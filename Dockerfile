# Dockerfile

# Build Stage
FROM node:18-alpine AS build
RUN npm install -g npm@latest # Good practice to use the latest npm

WORKDIR /opt/app
COPY package.json package-lock.json ./
RUN npm install --legacy-peer-deps
COPY . .
RUN npm run build

# Production Stage
FROM node:18-alpine AS production
WORKDIR /opt/app

# Copy production dependencies
COPY --from=build /opt/app/package.json ./
COPY --from=build /opt/app/package-lock.json ./
RUN npm install --omit=dev --legacy-peer-deps

# Copy the compiled admin panel (Corrected from 'dist' to 'build')
# ---- THIS IS THE MAIN FIX ----
COPY --from=build /opt/app/build ./build

# Copy Strapi configuration and other necessary folders
COPY --from=build /opt/app/config ./config
COPY --from=build /opt/app/database ./database
COPY --from=build /opt/app/public ./public
COPY --from=build /opt/app/src ./src

# Expose the Strapi port and start the application
EXPOSE 1337
CMD ["npm", "run", "start"]