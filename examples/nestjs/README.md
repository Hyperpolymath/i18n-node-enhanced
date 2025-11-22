# NestJS Integration Example

Enterprise TypeScript framework integration with dependency injection.

## Features

- Dependency injection pattern
- Module-based architecture
- Guards and interceptors for locale detection
- Decorator-based translation
- Request-scoped i18n instances
- Swagger/OpenAPI documentation support

## Setup

```bash
npm install
```

## Run

```bash
npm run dev
```

## Test

```bash
npm test
```

## Usage

### Module Registration

```typescript
import { I18nModule } from './i18n/i18n.module';

@Module({
  imports: [
    I18nModule.forRoot({
      locales: ['en', 'de', 'fr'],
      defaultLocale: 'en',
      directory: './locales'
    })
  ]
})
export class AppModule {}
```

### Controller with Translation

```typescript
import { Controller, Get } from '@nestjs/common';
import { I18nService } from './i18n/i18n.service';

@Controller('greetings')
export class GreetingsController {
  constructor(private readonly i18n: I18nService) {}

  @Get()
  async getGreeting() {
    return {
      message: this.i18n.__('greeting')
    };
  }
}
```

## API Endpoints

- `GET /greetings` - Get localized greeting
- `GET /greetings/:locale` - Get greeting in specific locale
- `GET /catalog` - Get current catalog
