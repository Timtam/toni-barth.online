export type Lang = 'en' | 'de';

export const siteTitle = 'Toni Barth';

export const langNames: Record<Lang, string> = {
  en: 'English',
  de: 'Deutsch',
};

export const otherLang: Record<Lang, Lang> = { en: 'de', de: 'en' };

export const ui: Record<
  Lang,
  {
    skipLink: string;
    navLabel: string;
    langLabel: string;
    otherHome: string;
    photoAlt: string;
  }
> = {
  en: {
    skipLink: 'Skip to main content',
    navLabel: 'Main navigation',
    langLabel: 'Language',
    otherHome: '/de/',
    photoAlt: 'Portrait photo of Toni Barth',
  },
  de: {
    skipLink: 'Zum Inhalt springen',
    navLabel: 'Hauptnavigation',
    langLabel: 'Sprache',
    otherHome: '/en/',
    photoAlt: 'Porträtfoto von Toni Barth',
  },
};

type NavLink = { label: string; href: string };
type NavEntry = NavLink | { label: string; children: NavLink[] };

// Mirrors NAVIGATION_LINKS from the old Nikola conf.py. As in the original,
// the navigation differs per language (Music is en-only; Externe Beiträge and
// Impressum are de-only).
export const navigation: Record<Lang, NavEntry[]> = {
  en: [
    { label: 'Home', href: '/en/' },
    { label: 'Resumé', href: '/en/resume/' },
    { label: 'Music', href: '/en/music/' },
    { label: 'Teaching', href: '/en/teaching/' },
    {
      label: 'Projects',
      children: [
        {
          label:
            'Hitster online - an online implementation of the award-winning music card game',
          href: 'https://hitster.toni-barth.online',
        },
        {
          label:
            'ReaHotkey - accessibility for various audio software and plugins',
          href: 'https://github.com/MatejGolian/ReaHotkey',
        },
        {
          label: 'Ear Dojo - accessible musical helpers in your browser',
          href: 'https://eardojo.com/',
        },
        {
          label: 'TCView - Audio file preview for Total Commander',
          href: 'https://github.com/Timtam/tcview',
        },
      ],
    },
    { label: 'Accessible audio hardware', href: '/en/gear/' },
    { label: 'Contact', href: '/en/contact/' },
    { label: 'Support Me', href: '/en/support/' },
    { label: 'Privacy Policy', href: '/en/privacy-policy/' },
  ],
  de: [
    { label: 'Startseite', href: '/de/' },
    { label: 'Schulungen', href: '/de/teaching/' },
    { label: 'Externe Beiträge', href: '/de/contributions/' },
    {
      label: 'Projekte',
      children: [
        {
          label:
            'Hitster online - Eine Online-Implementierung des preisgekrönten Musik-Kartenspiels',
          href: 'https://hitster.toni-barth.online',
        },
        {
          label:
            'ReaHotkey - Zugänglichkeit zu Audioplugins und -software (Englisch)',
          href: 'https://github.com/MatejGolian/ReaHotkey',
        },
        {
          label: 'Ear Dojo - barrierefreie Musiktheorie und Hilfsmittel im Browser',
          href: 'https://eardojo.com/',
        },
        {
          label: 'TCView - Vorschau für Audiodateien in Total Commander',
          href: 'https://github.com/Timtam/tcview',
        },
      ],
    },
    { label: 'Zugängliche Audio-Hardware', href: '/de/gear/' },
    { label: 'Kontakt', href: '/de/contact/' },
    { label: 'Unterstützung', href: '/de/support/' },
    { label: 'Impressum', href: '/de/imprint/' },
    { label: 'Datenschutzerklärung', href: '/de/privacy-policy/' },
  ],
};
