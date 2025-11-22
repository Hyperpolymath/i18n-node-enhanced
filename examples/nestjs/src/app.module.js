/**
 * App Module (JavaScript)
 * Main application module with i18n integration
 */

const { Module } = require('@nestjs/common');
const { I18nModule } = require('./i18n/i18n.module');
const { GreetingsController } = require('./greetings/greetings.controller');

const AppModule = {
  imports: [
    I18nModule.forRoot({
      locales: ['en', 'de', 'fr', 'es', 'ja'],
      defaultLocale: 'en',
      directory: './locales',
      updateFiles: false,
      syncFiles: false,
      autoReload: false,
      objectNotation: true,
      api: {
        __: '__',
        __n: '__n',
        __mf: '__mf',
        __l: '__l',
        __h: '__h'
      }
    })
  ],
  controllers: [GreetingsController],
  providers: []
};

// Apply NestJS decorator
Reflect.decorate(
  [Module(AppModule)],
  class AppModuleClass {}
);

module.exports = { AppModule: class AppModuleClass {} };
