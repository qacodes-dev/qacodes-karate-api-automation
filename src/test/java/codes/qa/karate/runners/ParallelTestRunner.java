package codes.qa.karate.runners;

import com.intuit.karate.Results;
import com.intuit.karate.Runner;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * CI / mvn-test runner. Executes all non-@ignore features in parallel across
 * 2 threads and writes Karate HTML reports to target/karate-reports/.
 */
class ParallelTestRunner {

    @Test
    void testParallel() {
        Results results = Runner
                .path("classpath:features")
                .tags("~@ignore")
                .parallel(2);

        assertEquals(0, results.getFailCount(), results.getErrorMessages());
    }
}
