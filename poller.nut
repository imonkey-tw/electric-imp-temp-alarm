// The class which holds the polling logic. It determines the logic of deep/shallow sleep of the imp and all the periods for that. 
// On each poll cycle it reads the temperature from the sensor and calls the processor instance with the obtained value.
//
// The required constructor parameters for the class: 
//      sensor - the temp sensor, it should implement getTemp() method
//      processor - the processor, it should implement boolean process(value) method 
//
// The optionsal table in constructor may include the following fields:
//      deepSleep - determines if the imp should go to deep sleep between polling. It is useful to wake up the impee by the sensor if temp is out of boundaries
//      regularSleepPeriod - sets the sleep period in seconds between polling
//      alertSleepPeriod - sets the sleep period in seconds between polling if the conversion resulted in alert 
//      errorRetryPeriod - sets the sleep period in seconds between polling if the conversion faulted
//      verbose - enables/disables the logging

class Poller {

    // the defaults table holds the defaults options
    defaults = {
        deepSleep = false,
        regularSleepPeriod = 600,
        alertSleepPeriod = 120,
        errorRetryPeriod = 10,
        verbose = true
    }
    
    // instance variables
    sensor = null;
    processor = null;
    options = {};

    // The required constructor parameters for the class: 
    //      sensor - the temp sensor, it should implement getTemp() method
    //      processor - the processor, it should implement boolean process(value) method
    // The optional opts table holds the options for the instance tuning (see in class description)  
    constructor(sensor, processor, opts = {}) {
        this.sensor = sensor;
        this.processor = processor;
        this.options = Utils.extend({}, defaults, opts);
        this.log(format("Poller configured: Deep=%s SP=%d/%d/%d", Utils.b(options.deepSleep), options.regularSleepPeriod, options.alertSleepPeriod, options.errorRetryPeriod));    
    };
    
    // The main poll logic of the class
    function poll() {
        try {
            local temp = sensor.getTemp();
            this.log("Got temp: " + temp);
            local alert = processor.process(temp);
            this.sleep(alert);
        } catch (error) {
            this.log(error);
            local self = this;
            imp.wakeup(options.errorRetryPeriod, function() { self.poll() });
        }
    }
    
    // forces impee to deep or shallow sleep for the period depending on the alert state of the conversion
    function sleep(alert) {
        local self = this;
        local sleepPeriod = alert ? options.alertSleepPeriod : options.regularSleepPeriod; 
        if (options.deepSleep) {
            //deep sleep is done inside imp.onidle according to http://devwiki.electricimp.com/doku.php?id=electricimpapi:server:sleepfor
            imp.onidle(function() { server.sleepfor(sleepPeriod); });
        } else {
            //shallow sleep
            imp.wakeup(sleepPeriod, function() { self.poll() });
        }
    }
    
    // logs arg to server.log if verbose mode is enabled in options    
    function log(arg) {
        if (options.verbose) server.log(arg);
    }
}
