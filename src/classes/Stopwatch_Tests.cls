@isTest
private class Stopwatch_Tests {
    @isTest
    static void it_should_throw_when_reading_elapsed_time_before_starting() {
        try {
            new Stopwatch().getElapsedCpuTimeMillis();
            System.assert(false, 'Expected a StopwatchException to be thrown');
        } catch(Stopwatch.StopwatchException ex) {
            System.assert(true);
        }
    }

    @isTest
    static void it_should_report_a_non_negative_elapsed_time_while_running() {
        Stopwatch stopwatch = new Stopwatch().start();

        System.assert(stopwatch.getElapsedCpuTimeMillis() >= 0);
    }

    @isTest
    static void it_should_report_a_fixed_elapsed_time_once_stopped() {
        Stopwatch stopwatch = new Stopwatch().start();
        stopwatch.stop();

        Integer firstReading = stopwatch.getElapsedCpuTimeMillis();
        Integer secondReading = stopwatch.getElapsedCpuTimeMillis();

        System.assertEquals(firstReading, secondReading);
    }

    @isTest
    static void it_should_restart_cleanly_when_started_a_second_time() {
        Stopwatch stopwatch = new Stopwatch().start();
        stopwatch.stop();

        stopwatch.start();

        System.assert(stopwatch.getElapsedCpuTimeMillis() >= 0);
    }
}
