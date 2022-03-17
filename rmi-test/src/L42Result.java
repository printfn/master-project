public record L42Result(long executionTimeNanos) {
    public String formatOutput() {
        return String.format("Time: %.3f s", this.executionTimeNanos / 1e9);
    }
}
