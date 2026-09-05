/**
 * Wraps Limits.getCpuTime() so benchmark tests can report a number instead
 * of a human eyeballing debug logs (which is how the original README
 * benchmark tables were produced). start() then stop(), or read
 * getElapsedCpuTimeMillis() while still running for a live reading.
 */
public class Stopwatch {
    private Integer startCpuTimeMillis;
    private Integer stopCpuTimeMillis;
    private Boolean isRunning = false;

    public Stopwatch start() {
        this.startCpuTimeMillis = Limits.getCpuTime();
        this.stopCpuTimeMillis = null;
        this.isRunning = true;
        return this;
    }

    public Stopwatch stop() {
        if(this.isRunning) {
            this.stopCpuTimeMillis = Limits.getCpuTime();
            this.isRunning = false;
        }
        return this;
    }

    public Integer getElapsedCpuTimeMillis() {
        if(this.startCpuTimeMillis == null) {
            throw new StopwatchException('Stopwatch was never started');
        }
        Integer endCpuTimeMillis = this.isRunning ? Limits.getCpuTime() : this.stopCpuTimeMillis;
        return endCpuTimeMillis - this.startCpuTimeMillis;
    }

    public class StopwatchException extends Exception {}
}
