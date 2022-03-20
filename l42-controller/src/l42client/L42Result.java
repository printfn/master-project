package l42client;

public record L42Result(long executionTimeNanos) {
    public double executionTime() {
        return Math.round(executionTimeNanos() / 1e6) / 1e3;
    }

    public String formatOutput() {
        return String.format("Time: %.3f s", executionTime());
    }
}
