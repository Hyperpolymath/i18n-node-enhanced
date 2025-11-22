/**
 * NestJS Application Entry Point (JavaScript)
 */

require('reflect-metadata');
const { NestFactory } = require('@nestjs/core');
const { AppModule } = require('./app.module');

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Enable CORS if needed
  app.enableCors();

  // Global prefix
  app.setGlobalPrefix('api');

  const port = process.env.PORT || 3000;

  await app.listen(port);

  console.log(`
🚀 NestJS i18n Example Server Running!

   Port: ${port}
   URL:  http://localhost:${port}/api

   Endpoints:
   - GET  /api/greetings
   - GET  /api/greetings/locales
   - GET  /api/greetings/catalog
   - GET  /api/greetings/:locale
   - GET  /api/greetings/plural/:count

   Try:
   - http://localhost:${port}/api/greetings?locale=de
   - http://localhost:${port}/api/greetings?locale=fr&name=Claude
   - http://localhost:${port}/api/greetings/plural/5?locale=es
  `);
}

bootstrap().catch(err => {
  console.error('Failed to start application:', err);
  process.exit(1);
});
