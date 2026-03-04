FROM node:24-alpine3.23 as base

# Stage 1: Builder 
FROM base as builder
 
WORKDIR /home/build

COPY package*.json .
COPY tsconfig.json .

RUN npm install
COPY src/ src/
RUN npm run build


# Stage 2: Runner
FROM base as runner

WORKDIR /home/app 
# Since there is dist folder produced in the stage 1
COPY --from=builder /home/build/dist dist/
COPY --from=builder /home/build/package*.json .

# will only install the required deps by project only not dev deps, damnn
RUN npm install --omit=dev

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001  nodejs
USER nodejs

EXPOSE 8000
ENV PORT=8000

CMD ["npm","start"]