package codes.qa.karate.runners;

import com.intuit.karate.junit5.Karate;

/**
 * IDE runner — right-click → Run in IntelliJ / VS Code to execute all features
 * (or just the @smoke subset). Excluded from the default mvn test run; use
 * ParallelTestRunner for CI and command-line execution.
 */
class KarateTestRunner {

    @Karate.Test
    Karate testAll() {
        return Karate.run("classpath:features").tags("~@ignore");
    }

    @Karate.Test
    Karate testSmoke() {
        return Karate.run("classpath:features").tags("@smoke", "~@ignore");
    }
}
