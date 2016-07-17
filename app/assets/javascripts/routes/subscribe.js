/* global StripeCheckout */
import $ from 'jquery';

const subscribe = {
  loading: false,

  init: () => {
    subscribe.handler = StripeCheckout.configure({
      key: window.STRIPE_PUBLISHABLE_KEY,
      image: 'https://s3.amazonaws.com/stripe-uploads/acct_17FbXPKOnaks6VJBmerchant-icon-1450654427617-bot.png',
      locale: 'auto',
      email: window.USER.email,
      allowRememberMe: false
    });

    $(document).on('submit', '.subscribe', subscribe.requestPaymentDetails);
    $(document).on('input', '#search', subscribe.filterRepos);
    $(window).on('popstate', subscribe.closePaymentDetails);
    setInterval(subscribe.loadRepos, 2000);
    setImmediate(subscribe.loadRepos);
  },

  requestPaymentDetails: (ev) => {
    const $form = $(this);
    const data = $form.serializeObject();
    const privateRepo = (data.private === 'true');

    if (privateRepo && !data.has_customer && !data.token) {
      subscribe.handler.open({
        name: 'Pushbit',
        description: data.name,
        panelLabel: 'Subscribe',
        amount: 1500,
        token: (token) => {
          // add the payment token and resubmit as we now have the neccessaries
          $form.find('input[name=token]').val(token.id);
          $form.submit();
        }
      });
      ev.preventDefault();
    } else {
      $form.find('button')
        .text('Subscribing...')
        .attr('disabled', true);
    }
  },

  closePaymentDetails: () => {
    subscribe.handler.close();
  },

  filterRepos: () => {
    const term = $(this).val();
    $('li.repo').hide();
    $(`li.repo:containsi(${term})`).show();
  },

  loadRepos: () => {
    const $holder = $('#repositories');
    const hasRepos = !$holder.find('ul').length;

    if (!subscribe.loading && $holder.length && hasRepos) {
      subscribe.loading = true;

      $holder.load('/repos', () => {
        subscribe.loading = false;

        if ($holder.find('ul').length) {
          $('.search').show();
        }
      });
    }
  }
};

export default subscribe;
