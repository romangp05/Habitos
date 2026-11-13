import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors({
    exposedHeaders: ['X-Response-Time-Ms'],
  });

  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`🚀 API de Gamificación (TypeScript/NestJS) activa en: http://localhost:${port}/api/v1/gamificacion`);
}
bootstrap();