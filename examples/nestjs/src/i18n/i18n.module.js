/**
 * I18n NestJS Module (JavaScript)
 * No TypeScript - pure JavaScript with decorators via reflect-metadata
 */

const { Module, Global, DynamicModule } = require('@nestjs/common');
const { I18nService } = require('./i18n.service');
const { I18nInterceptor } = require('./i18n.interceptor');

class I18nModule {
  static forRoot(options = {}) {
    return {
      module: I18nModule,
      providers: [
        {
          provide: 'I18N_OPTIONS',
          useValue: options
        },
        I18nService,
        I18nInterceptor
      ],
      exports: [I18nService, I18nInterceptor],
      global: true
    };
  }

  static forRootAsync(options) {
    return {
      module: I18nModule,
      imports: options.imports || [],
      providers: [
        {
          provide: 'I18N_OPTIONS',
          useFactory: options.useFactory,
          inject: options.inject || []
        },
        I18nService,
        I18nInterceptor
      ],
      exports: [I18nService, I18nInterceptor],
      global: true
    };
  }
}

// Apply NestJS decorators
Reflect.decorate(
  [Global(), Module({})],
  I18nModule
);

module.exports = { I18nModule };
