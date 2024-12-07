package com.filichkin.lambda;


import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyRequestEvent;
import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyResponseEvent;
import io.opentelemetry.api.GlobalOpenTelemetry;
import io.opentelemetry.api.common.AttributeKey;
import io.opentelemetry.api.common.Attributes;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.exporter.otlp.trace.OtlpGrpcSpanExporter;
import io.opentelemetry.sdk.OpenTelemetrySdk;
import io.opentelemetry.sdk.trace.SdkTracerProvider;
import io.opentelemetry.sdk.trace.export.BatchSpanProcessor;
import org.crac.Context;
import org.crac.Core;
import org.crac.Resource;

import java.util.concurrent.TimeUnit;

public class SampleHandler implements RequestHandler<APIGatewayProxyRequestEvent, APIGatewayProxyResponseEvent>, Resource {

    private static final String OTEL_ENDPOINT = "http://18.200.252.40:4317";

    private static final BatchSpanProcessor SPAN_PROCESSOR = BatchSpanProcessor.builder(OtlpGrpcSpanExporter.builder().setEndpoint(OTEL_ENDPOINT).build()).build();
    static {
        // Set up OpenTelemetry SDK
        SdkTracerProvider tracerProvider = SdkTracerProvider.builder().addResource(io.opentelemetry.sdk.resources.Resource.create(Attributes.of(AttributeKey.stringKey("service.name"), "lambda"))).addSpanProcessor(SPAN_PROCESSOR).build();
        OpenTelemetrySdk.builder().setTracerProvider(tracerProvider).buildAndRegisterGlobal();
    }
    private static final Tracer tracer = GlobalOpenTelemetry.getTracer("LambdaTracer");

    public SampleHandler() {
        Core.getGlobalContext().register(this);
    }
    @Override
    public void beforeCheckpoint(Context<? extends Resource> context) {
        Span span = tracer.spanBuilder("SnapStart").startSpan();
        span.end();// End the span
        SPAN_PROCESSOR.forceFlush().join(10, TimeUnit.SECONDS);
    }

    @Override
    public void afterRestore(Context<? extends Resource> context){

    }

    public APIGatewayProxyResponseEvent handleRequest(APIGatewayProxyRequestEvent apiGatewayProxyRequestEvent, com.amazonaws.services.lambda.runtime.Context context) {
        // Start a span to trace the Lambda invocation
        Span span = tracer.spanBuilder("LambdaInvocation").startSpan();
        try {
            APIGatewayProxyResponseEvent apiGatewayProxyResponseEvent = new APIGatewayProxyResponseEvent();
            apiGatewayProxyResponseEvent.setBody("hello world");
            return apiGatewayProxyResponseEvent;
        } finally {
            span.end();// End the span
            SPAN_PROCESSOR.forceFlush().join(10, TimeUnit.SECONDS);
        }
    }


}
