/**
 * Tests for Fastify + i18n example
 */

const { expect } = require('chai');

describe('Fastify i18n Integration', () => {
  let app;

  before(async () => {
    app = require('./index');
    await app.ready();
  });

  after(async () => {
    await app.close();
  });

  it('should return English by default', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/'
    });

    expect(response.statusCode).to.equal(200);
    expect(response.body).to.include('Welcome');
  });

  it('should switch to German via query parameter', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/?lang=de'
    });

    expect(response.statusCode).to.equal(200);
    expect(response.body).to.include('Willkommen');
  });

  it('should return translation catalog via API', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/api/translations?locale=en'
    });

    expect(response.statusCode).to.equal(200);

    const data = JSON.parse(response.body);
    expect(data).to.have.property('locale', 'en');
    expect(data).to.have.property('catalog');
    expect(data).to.have.property('availableLocales');
  });

  it('should set locale via POST API', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/api/locale',
      payload: { locale: 'fr' },
      headers: {
        'content-type': 'application/json'
      }
    });

    expect(response.statusCode).to.equal(200);

    const data = JSON.parse(response.body);
    expect(data).to.have.property('success', true);
    expect(data).to.have.property('locale', 'fr');
  });

  it('should reject invalid locale', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/api/translations?locale=invalid'
    });

    expect(response.statusCode).to.equal(400);
  });

  it('should translate specific key', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/api/translate/Hello?locale=de'
    });

    expect(response.statusCode).to.equal(200);

    const data = JSON.parse(response.body);
    expect(data).to.have.property('key', 'Hello');
    expect(data).to.have.property('locale', 'de');
    expect(data).to.have.property('translation');
  });

  it('should return health status', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/health'
    });

    expect(response.statusCode).to.equal(200);

    const data = JSON.parse(response.body);
    expect(data).to.have.property('status', 'ok');
    expect(data).to.have.property('locales');
  });
});
