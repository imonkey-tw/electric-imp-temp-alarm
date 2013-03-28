// Utils class is just a placeholder for different utils functions
class Utils {    
    // extend function extends and overrifes fields of target table with the fields of one or more source tables
    // it is inspired by jQuery.extend() 
    function extend(target, ...) {
        foreach(i, val in vargv) {
            if (typeof val != "table") throw "Expect table-type arguments: " + typeof val; 
            foreach (key, tval in val) {
                 target[key] <- tval;
            }
        }
        return target;
    }
    
    // function for pretty output of boolean values
    function b(bool) {
        return bool ? "true" : "false";
    }
    
    // function for pretty output of nullable values
    function n(nullable) {
        return nullable == null ? "NA" : nullable.tostring(); 
    }
    
    // watchdog timer to fix imp issue of going offline when the code is inactive for too long time
    function watchdog() {
        local self = this;
        imp.wakeup(30*60, function() { self.watchdog() });
    }    
}
