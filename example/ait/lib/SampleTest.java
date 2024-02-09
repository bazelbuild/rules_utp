/**
 * Copyright 2024 The Bazel Authors. All rights reserved.
 *
 * <p>Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy of the License at
 *
 * <p>http://www.apache.org/licenses/LICENSE-2.0
 *
 * <p>Unless required by applicable law or agreed to in writing, software distributed under the
 * License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.sample;

import static androidx.test.espresso.Espresso.onView;
import static androidx.test.espresso.assertion.ViewAssertions.matches;
import static androidx.test.espresso.matcher.ViewMatchers.withId;
import static androidx.test.espresso.matcher.ViewMatchers.withText;

import androidx.test.ext.junit.runners.AndroidJUnit4;
import androidx.test.core.app.ActivityScenario;
import com.sample.SampleActivity;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

/** Sanity Espresso tests for the Unified Test Platform to use. */
@RunWith(AndroidJUnit4.class)
public class SampleTest {

  @Before
  public void setUp() {}

  @Test
  public void helloWorldDoesNotBlowUp() {
    ActivityScenario.launch(SampleActivity.class);
  }

  @Test
  public void helloWorldIsDisplayed() {
    ActivityScenario.launch(SampleActivity.class);
    System.out.println(
        "helloWorldIsDisplayed... "
            + withId(R.string.hello_world)
            + " / "
            + withId(R.string.app_name));
    onView(withId(R.id.text_hello)).check(matches(withText("Hello world!")));
  }
}
