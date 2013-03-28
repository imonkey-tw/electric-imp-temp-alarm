// Tmp102Sensor class wraps the TI TMP102 chip logic, some kind of Squirell-driver for that chip.
// The details of the chip logic can be found here: http://www.ti.com/lit/ds/symlink/tmp102.pdf
// TI TMP102 talks through I2C interface, so the usage of I2C bus of the Imp is required. 

// The only required parameter to instantiate a sensor instance is the i2c port of the imp (hardware.i2c89 or hardware.i2c12) 
// The instanse can be tuned by options table which may include following fields:
//     i2cAddress  - the address of the sensor on the i2c bus. The default one is 0x49
//     extMode     - if enabled the sensor uses 13bits to represent the temperature, otherwise 12 bits are in use by default
//     lowLimit    - the value of low-limit temp register to set at instantiation time
//     highLimit   - the value of high-limit temp register to set at instantiation time
//     wakeupTemp  - single boundary value to be used instead of lowWakeup/highWakeup pair. If specified, the lowWakeup/highWakeup values are ignored
//     sleepAfterInit - the pause to wait for the conversion to happen after the configuration of sensor has changed
//     verbose     - if true, the instance will log to server its life events

// The interface consists of the following methods:
//     getTemp() - returns the current temp as float value
//     getLowLimit() - returns the low-limit register temp value
//     getHighLimit() - returns the high-limit register temp value
//     getConf() - returns the integer which represents the value of configuration register
//     setLowLimit(temp) - updates the value of low-limit temp register
//     setHighLimit(temp) - updates the value of high-limit temp register
//     setWakeupTemp(temp) - updates the values of low/high-limit registers with the single boundary value
//     setConf(bytes) - updates the value of conf register, argument should be a 2-byte array
class Tmp102Sensor {
    
    //constanst for the sensor logic
    tempRegAddr = 0x0; //the address of temp register
    confRegAddr = 0x1; //the address of configuration register
    lowRegAddr  = 0x2; //the address of low-limit register
    highRegAddr = 0x3; //the address of high-limit register
    tempResolution = 0.0625;  //the temperature resolution of the sensor

    // the defaults table holds the defaults options for the sensor
    defaults = {
        i2cAddress = 0x49
        extMode = false 
        lowLimit = null
        highLimit = null
        wakeupTemp = null
        sleepAfterInit = 1.0
        verbose = true
    }

    // instance variables
    options = {};
    i2cPort = null;
    tempBits = 12;
    
    // the only required parameter for constructor is i2cPort, which can be hardware.i2c89 or hardware.i2c12
    // the optional opts table holds the options for the instance tuning (see in class description)  
    constructor(i2cPort, opts = {}) {
        this.i2cPort = i2cPort;
        this.options = Utils.extend({}, defaults, opts);
        this.initConf();                                                       // init the configuration register of the sensor
        if (options.wakeupTemp !=null) {
            setWakeupTemp(options.wakeupTemp);                                 // update the low&high limit registers
        } else {
            if (options.lowLimit != null) setLowLimit(options.lowLimit);       // update the low-limit register
            if (options.highLimit != null) setHighLimit(options.highLimit);    // update the high-limit register
        }
        if (options.sleepAfterInit > 0) {
             imp.sleep(options.sleepAfterInit); // sleep to allow a conversion to happen with updated configuration   
        }       
        server.log(format("Tmp102 configured: ADDR=0x%X LT=%.1f HT=%.1f EM=%s Conf=0x%X Temp=%.1f", options.i2cAddress, getLowLimit(), getHighLimit(), Utils.b(options.extMode), getConf(), getTemp()));
    } 
        
    // inits the configuration register of the sensor
    // the following defaults settings are overriden:
    //    the conversion rate is set to 1Hz
    //    the fault settings set to 2 conversions
    //    the polarity of alert bit is inverted
    //    the termostat mode is set to INTERRUPT mode
    //Configuration register structure (see in datasheet): 
    //    0-OneShotMod 11-ReadOnlyBits 01-FaultQueueLen 1-AlertPolarity 1-TermMode 0-ShutdownMode  01-convrate 1-ReadOnlyBit 0-ExtMode  0000
    function initConf() {
        local resolutionMode = options.extMode ? 0x10 : 0x0;
        local conf = 0x6E60 | resolutionMode;
        //local conf = 0x6A60 | resolutionMode;
        local confBytes = [conf >> 8, conf & 0xff];
        this.setConf(confBytes);
    }    
    
    // returns the current value of the temp register
    function getTemp() {
        return decodeTemp(getRegistor(tempRegAddr, 2));
    }    
    
    // returns the current value of the low-limit register
    function getLowLimit() {
        return decodeTemp(getRegistor(lowRegAddr, 2));
    }

    // returns the current value of the high-limit register
    function getHighLimit() {
        return decodeTemp(getRegistor(highRegAddr, 2));
    }

    // updates the values of low/high-limit registers with the single boundary value
    function setWakeupTemp(temp) {
        setLowLimit(temp);
        setHighLimit(temp);
    }

    // updates the value of the low-limit register
    function setLowLimit(temp) {
        setRegistor(lowRegAddr, encodeTemp(temp));
    }

    // updates the value of the high-limit register
    function setHighLimit(temp) {
        setRegistor(highRegAddr, encodeTemp(temp));
    }

    // returns the current value of the conf register
    function getConf() {
        local bytes = getRegistor(confRegAddr, 2);
        return bytes[0] << 8 | bytes[1];
    }
    
    // updates the value of the conf register
    function setConf(bytes) {
        setRegistor(confRegAddr, bytes);
    }

    // decode 2-bytes array as a temperature value according to chip spec
    function decodeTemp(bytes) {
        local tempBits = options.extMode ? 13 : 12;
        local msb = bytes[0], lsb = bytes[1];
        local bit12 = (msb << 8 | lsb) >> (16 - tempBits);
        local temp = msb >> 7 == 0 ? bit12 : -(1 << tempBits) + bit12;
        return temp * tempResolution;
    }
    
    // encode temp value to 2-bytes array according to chip spec
    function encodeTemp(tempValue) {
        local tempBits = options.extMode ? 13 : 12;
        local digital = (math.floor(tempValue / tempResolution)).tointeger();
        //local encoded = digital > 0 ? digital : (1 << tempBits) + digital;
        local shifted = digital << (16-tempBits);
        return [(shifted >> 8) & 0xff , shifted & 0xff];
    }    
    
    // reads a bytes-number of bytes from register with regAddr address, returns array of bytes
    function getRegistor(regAddr, bytes) {
        if (regAddr == null) throw "Incorrest registor address"; 
        local bytes = i2cPort.read(options.i2cAddress << 1, format("%c", regAddr), bytes);
        if (bytes == null) throw "I2C Read Failure: " + regAddr;
        return bytes;   
    };   

    // updates a register at regAddr with 2-bytes value
    function setRegistor(regAddr, bytes) {
        local res = i2cPort.write(options.i2cAddress << 1, format("%c%c%c", regAddr, bytes[0], bytes[1]));
        if (res != 0) throw "I2C write failure: " + regAddr + " : " + bytes;
    };
    
    // logs arg to server.log if verbose mode is enabled in options
    function log(arg) {
        if (this.options.verbose) server.log(arg);
    }    
}
