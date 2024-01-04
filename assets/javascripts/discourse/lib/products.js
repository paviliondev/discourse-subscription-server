import { helperContext } from "discourse-common/lib/helpers";

const customProducts = () => {
  const siteSettings = helperContext().siteSettings;

  return [
    {
      name: 'Custom Wizard Community',
      description: `<p>${siteSettings.custom_wizard_community_subscription_description}</p>`,
      btnLabel: 'Apply',
      btnHref: siteSettings.custom_wizard_community_subscription_href,
      custom: true,
    },
    {
      name: 'Custom Wizard Enterprise',
      description: `<p>${siteSettings.custom_wizard_enterprise_subscription_description}</p>`,
      btnLabel: 'Contact Us',
      btnHref: siteSettings.custom_wizard_enterprise_subscription_href,
      custom: true,
    }
  ];
}

const productOrder = [
  'Custom Wizard Community',
  'Custom Wizard Small Business',
  'Custom Wizard Business',
  'Custom Wizard Enterprise'
];

export {
  customProducts,
  productOrder
}
