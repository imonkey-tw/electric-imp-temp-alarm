// instantiating the impee with defaults parameters 
local impee  = Impee({powerSave = true});
    
// instantiating temp sensor with configured low/high-limit registers and extended mode
// common addresses for tmp102 chip: 0x48 (-), 0x49 (+), 0x4A (SDA), 0x4B (SCL)
local sensor = Tmp102Sensor(impee.getI2cPort(), { i2cAddress = 0x49, wakeupTemp=30, extMode = true});
    
// instantiating processor configured to alert data to SMS channel with temp threshold set to 50 degrees
local processor = Processor({highAlert = 50});
    
// instantiating the poller configured to deep sleep for 1 hour
local poller = Poller(sensor, processor, {regularSleepPeriod = 60, deepSleep = true});

// configuring the channels of the imp 
imp.configure("Temperature Sensor", [processor], processor.getOutputPorts());
    
// begin polling
poller.poll();
