// the class which holds the logic of temperature processing including alerting when temp boundaries are broken
// the class also implements the InputPort interface in order to be able to supply values via input port for testing purpose
// it creates two output ports: one for alerting (it is connected to SMS url in Planner) and one for regular logging (connected to Cosm node)

// The optionsal table in constructor may include the following fields:
//      lowAlert - the low boundary of temperature
//      highAler - the high boundary of temperature
//      voltageAlert - if set up, the voltage of the impee will be checked each time the temperature is processed and the alert will be issued if it is under the specified value
//      verbose - enables/disables the logging
class Processor extends InputPort {
    
    // the defaults table holds the defaults options
    defaults = {
        lowAlert = null
        highAlert = null
        voltageAlert = null
        verbose = true
    }
    
    // instance variables
    options = {};
    tempOutput = null;
    alertOutput = null;
    
    // the optional opts table holds the options for the instance tuning (see in class description)  
    constructor(opts = {}) {
        base.constructor("process test input");
        this.options = Utils.extend({}, defaults, opts);
        this.tempOutput = OutputPort("temperature", "number");;
        this.alertOutput = OutputPort("temp_alert", "string");;
        if (options.lowAlert != null && options.highAlert && options.lowAlert > options.highAlert) {
            throw "Wrong configuration, low threshold should be less than high threshold: " + options.lowAlert + " : " + options.highAlert; 
        }
        this.log(format("TempProcessor configured: LT=%s, HT=%s", Utils.n(options.lowAlert), Utils.n(options.highAlert)));
    }
    
    // the main logic of data processing 
    // returns true to indicate alert state or false otherwise
    function process(temp) {
        tempOutput.set(temp); // output the value to the regulat output port
        server.show(temp);
        if (options.lowAlert != null && temp <= options.lowAlert) {
            // the value is below low limit
            local msg = "Temp is under low threshold: " + temp;
            alertOutput.set(msg);
            this.log(msg);
            return true;
        }       
        if (options.highAlert != null && temp >= options.highAlert) {
            // the value if above high limit
            local msg = "Temp is above high threshold: " + temp;
            alertOutput.set(msg);
            this.log(msg);
            return true;
        }   
        if (options.voltageAlert && voltageAlert >= hardware.voltage()) {
            // the voltage value is below low limit
            local msg = "Voltage is below low threshold: " + hardware.voltage();
            alertOutput.set(msg);
            this.log(msg);
            return true;
        }
        return false;
    }
    
    //this is an interface of InputPort
    //we use this function to test processor with the value supplied from input port, for example by HttpRequest
    function set(value) {
        this.log("Input port value received: " + value);
        this.process(value);
    }
    
    // returns output ports for regular and alert channel
    function getOutputPorts() {
        return [tempOutput, alertOutput];
    }
    
    // logs arg to server.log if verbose mode is enabled in options    
    function log(arg) {
        if (options.verbose) server.log(arg);
    }
}
