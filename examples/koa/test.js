/**
 * Tests for Koa + i18n example
 */

const request = require('supertest');
const app = require('./index');

describe('Koa i18n Integration', () => {
  it('should return English by default', (done) => {
    request(app.callback())
      .get('/')
      .expect(200)
      .expect(/Welcome/)
      .end(done);
  });

  it('should switch to German via query parameter', (done) => {
    request(app.callback())
      .get('/?lang=de')
      .expect(200)
      .expect(/Willkommen/)
      .end(done);
  });

  it('should return translation catalog via API', (done) => {
    request(app.callback())
      .get('/api/translations?locale=en')
      .expect(200)
      .expect('Content-Type', /json/)
      .end((err, res) => {
        if (err) return done(err);
        if (res.body.locale !== 'en') return done(new Error('Locale mismatch'));
        if (!res.body.catalog) return done(new Error('Missing catalog'));
        done();
      });
  });

  it('should set locale via POST API', (done) => {
    request(app.callback())
      .post('/api/locale')
      .send({ locale: 'fr' })
      .expect(200)
      .expect('Content-Type', /json/)
      .end((err, res) => {
        if (err) return done(err);
        if (res.body.locale !== 'fr') return done(new Error('Locale not set'));
        done();
      });
  });

  it('should reject invalid locale', (done) => {
    request(app.callback())
      .get('/api/translations?locale=invalid')
      .expect(400)
      .end(done);
  });
});
