FROM python:3.9 AS builder

# Copy the whole repository into Docker container
COPY toni-barth.online/ . 

# Build the blog
RUN pip install nikola jinja2 \
    && nikola build

FROM nginx:alpine

# Copy output to the default nginx directory
COPY --from=builder output /usr/share/nginx/html

# Copy nginx host configuration
COPY nginx/default.conf /etc/nginx/conf.d/
