/**
 * Next.js Home Page with i18n
 */

import type { NextPage, GetStaticProps } from 'next';
import Link from 'next/link';
import { useRouter } from 'next/router';
import { i18n } from './_app';

interface HomeProps {
  translations: {
    title: string;
    welcome: string;
    description: string;
    changeLanguage: string;
  };
}

const Home: NextPage<HomeProps> = ({ translations }) => {
  const router = useRouter();
  const { locale, locales } = router;

  const changeLocale = (newLocale: string) => {
    router.push(router.pathname, router.asPath, { locale: newLocale });
  };

  return (
    <div style={{ padding: '2rem', fontFamily: 'sans-serif' }}>
      <h1>{translations.title}</h1>
      <p>{translations.welcome}</p>
      <p>{translations.description}</p>

      <div style={{ marginTop: '2rem' }}>
        <h2>{translations.changeLanguage}</h2>
        {locales?.map((loc) => (
          <button
            key={loc}
            onClick={() => changeLocale(loc)}
            style={{
              margin: '0.5rem',
              padding: '0.5rem 1rem',
              fontWeight: locale === loc ? 'bold' : 'normal',
              backgroundColor: locale === loc ? '#0070f3' : '#eee',
              color: locale === loc ? 'white' : 'black',
              border: 'none',
              borderRadius: '4px',
              cursor: 'pointer'
            }}
          >
            {loc.toUpperCase()}
          </button>
        ))}
      </div>

      <div style={{ marginTop: '2rem' }}>
        <h3>Current Locale: {locale}</h3>
        <p>Available Locales: {locales?.join(', ')}</p>
      </div>
    </div>
  );
};

export const getStaticProps: GetStaticProps<HomeProps> = async ({ locale }) => {
  // Set locale for server-side rendering
  if (locale) {
    i18n.setLocale(locale);
  }

  return {
    props: {
      translations: {
        title: i18n.__('home.title'),
        welcome: i18n.__('home.welcome'),
        description: i18n.__('home.description'),
        changeLanguage: i18n.__('home.changeLanguage')
      }
    }
  };
};

export default Home;
