package com.example.starter.behaviors.ordering.runners;

import static io.cucumber.junit.platform.engine.Constants.GLUE_PROPERTY_NAME;
import static io.cucumber.junit.platform.engine.Constants.PLUGIN_PROPERTY_NAME;

import org.junit.platform.suite.api.ConfigurationParameter;
import org.junit.platform.suite.api.IncludeEngines;
import org.junit.platform.suite.api.SelectClasspathResource;
import org.junit.platform.suite.api.Suite;

@Suite
@IncludeEngines("cucumber")
@SelectClasspathResource("behaviors/ordering/place_order.feature")
@ConfigurationParameter(key = GLUE_PROPERTY_NAME, value = "com.example.starter.behaviors.ordering.steps.place_order")
@ConfigurationParameter(key = PLUGIN_PROPERTY_NAME, value = "pretty, html:build/reports/behaviors/ordering/place-order.html")
public class PlaceOrderBehaviorTest {
}
