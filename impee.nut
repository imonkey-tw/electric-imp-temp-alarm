// the class that wraps the impee configuration
// the constructor has no required fields
// the optional table can be used to tune the impee with the following fields:
//      i2cPort - the pins to configure as I2C bus, the default is hardware.i2c89
//      clockSpeed - the clock speed of the I2C bus, the default is CLOCK_SPEED_100_KHZ
//      powerSave - enables/disables power save mode for the imp
//      blinkUp   - enables/disables blink up of the imp led
//      wakeupPin - enables/disables the wakeup pin (pin1) of the imp, which is required if running deep sleep with wake up from the temp sensor
//      verbose - enables/disables the logging

class Impee {
    
    // the defaults table holds the defaults options
    defaults = {
        i2cPort = hardware.i2c89
        clockSpeed = CLOCK_SPEED_50_KHZ        
        powerSave = true
        blinkUp = true
        wakeupPin = true
        verbose = true
    }
    // instance variables
    options = {};
    
    // the constructor has no required fields
    // the optional opts table holds the options for the instance tuning (see in class description)    
    constructor(opts = {}) {
        this.options = Utils.extend({}, defaults, opts);
        imp.setpowersave(options.powerSave);
        imp.enableblinkup(options.blinkUp); 
        options.i2cPort.configure(options.clockSpeed);
        if (options.wakeupPin) hardware.pin1.configure(DIGITAL_IN_WAKEUP);
        this.log(format("Impee configured: PowerSave=%s Blink=%s WakePin=%s", Utils.b(options.powerSave), Utils.b(options.blinkUp), Utils.b(options.wakeupPin)));
        reportState();
    };

    // function logs the state of the impee, including voltage, wi-fi signal and etc.
    function reportState() {
        this.log(format("Voltage=%.3f Wi-fi=%d Mac=%s BSMac=%s Memory=%d ImpeeId=%s ", hardware.voltage(), imp.rssi(), imp.getmacaddress(), imp.getbssid(), imp.getmemoryfree(), hardware.getimpeeid()));
    }

    // returns configured I2C bus port
    function getI2cPort() {
        return options.i2cPort;
    };
    
    // returns the impee Id
    function getId() {
        return impeeId;
    }
    
    // logs arg to server.log if verbose mode is enabled in options
    function log(arg) {
        if (options.verbose) server.log(arg);
    }
}
