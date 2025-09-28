## Production Dockerfile (expects local build artifacts)
##
## This Dockerfile no longer builds the app inside the image. Instead,
## it expects you to run the Node build locally (or in CI) so that a
## `dist/` directory exists in the project root. This avoids pulling
## the Node image during `docker build`.
##
## Usage:
##   # build locally (on your Windows/Linux host)
##   npm ci
##   npm run build
##   # then build the image
##   docker build -t my-react-app:latest .
##
## Note: Docker still needs to pull the `nginx` base image unless you
## already have it locally. Use `docker pull nginx:stable-perl` beforehand
## or provide a local image and run `docker build --pull=false`.

FROM nginx:stable-perl

# Copy the static build output (must be created before docker build)
COPY dist/ /usr/share/nginx/html/

# Copy nginx config if present (optional)
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
