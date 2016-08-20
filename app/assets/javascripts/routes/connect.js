/* global StripeCheckout */
import $ from 'jquery';
import {serializeObject} from '../libs/forms';

$.extend($.expr[':'], {
  containsi: (elem, i, match) =>
    (elem.textContent || elem.innerText || '').toLowerCase()
    .indexOf((match[3] || '').toLowerCase()) >= 0
});

const connect = {
  loading: false,

  init: () => {
    connect.handler = StripeCheckout.configure({
      key: window.STRIPE_PUBLISHABLE_KEY,
      image: 'https://s3.amazonaws.com/stripe-uploads/acct_17FbXPKOnaks6VJBmerchant-icon-1450654427617-bot.png',
      locale: 'auto',
      email: window.USER.email,
      allowRememberMe: false
    });

    $(document).on('submit', '.subscribe', connect.requestPaymentDetails);
    $(document).on('input', '#search', connect.filterRepos);
    $(window).on('popstate', connect.closePaymentDetails);
    setInterval(connect.loadRepos, 2000);
    setImmediate(connect.loadRepos);
  },

  requestPaymentDetails: (ev) => {
    const $form = $(ev.target).parents('form');
    const data = serializeObject(this);
    const privateRepo = (data.private === 'true');

    if (privateRepo && !data.has_customer && !data.token) {
      connect.handler.open({
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
    connect.handler.close();
  },

  filterRepos: (ev) => {
    const term = $(ev.currentTarget).val();
    $('li.repo').hide();
    $(`li.repo:containsi(${term})`).show();
  },

  loadRepos: () => {
    const $holder = $('#repositories');
    const hasRepos = !$holder.find('ul').length;

    if (!connect.loading && $holder.length && hasRepos) {
      connect.loading = true;

      $holder.load('/repos', () => {
        connect.loading = false;

        if ($holder.find('ul').length) {
          $('.search').show();
        }
      });
    }
  }
};

export default connect;
