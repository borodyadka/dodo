# FROM not-valid-image
FROM alpine:latest AS first-step

RUN echo foo bar && \
  from alpine:never

FROM not-valid-image AS second-step
