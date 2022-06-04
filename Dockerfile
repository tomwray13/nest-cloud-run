###################
# BUILD FOR LOCAL DEVELOPMENT
###################

FROM node:18-alpine As development

# https://btholt.github.io/complete-intro-to-containers/build-a-nodejs-app
USER node

# Create app directory
WORKDIR /usr/src/app

# Copy application dependency manifests to the container image.
# A wildcard is used to ensure copying both package.json AND package-lock.json (when available).
# Copying this first prevents re-running npm install on every code change.
COPY --chown=node:node package*.json ./

# Install app dependencies
RUN npm ci

# Bundle app source
COPY --chown=node:node . .

###################
# BUILD FOR PRODUCTION
###################

# Base image for production
FROM node:18-alpine As build

USER node

# Create app directory
WORKDIR /usr/src/app

COPY --chown=node:node package*.json ./

COPY --chown=node:node --from=development /usr/src/app/node_modules ./node_modules

# Bundle app source
COPY --chown=node:node . .

RUN npm run build

# Set NODE_ENV environment variable
ENV NODE_ENV production

RUN npm ci --only=production && npm cache clean --force

###################
# PRODUCTION
###################

# Base image for production
FROM node:18-alpine As production

# Copy the bundled code to the production image
COPY --chown=node:node --from=build /usr/src/app/node_modules ./node_modules
COPY --chown=node:node --from=build /usr/src/app/dist ./dist

# Start the server using the production build
CMD [ "node", "dist/main.js" ]