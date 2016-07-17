/* global $ StripeCheckout */
export default {
  init: () => {
    if (window.USER) {
      const handler = StripeCheckout.configure({
        key: window.STRIPE_PUBLISHABLE_KEY,
        image: 'https://s3.amazonaws.com/stripe-uploads/acct_17FbXPKOnaks6VJBmerchant-icon-1450654427617-bot.png',
        locale: 'auto',
        email: window.USER.email,
        allowRememberMe: false
      });

      // process card details into stripe token if needed
      $(document).on('submit', '.subscribe', (ev) => {
        const $form = $(this);
        const data = $form.serializeObject();
        const privateRepo = (data.private === 'true');

        if (privateRepo && !data.has_customer && !data.token) {
          handler.open({
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
      });

      // closes Stripe checkout on page unload
      $(window).on('popstate', () => {
        handler.close();
      });
    }

    $('#search').on('keydown', (ev) => {
      if (event.keyCode === 13) {
        ev.preventDefault();
        return false;
      }
      return true;
    });

    $('#search').on('input', () => {
      const term = $(this).val();
      $('li.repo').hide();
      $(`li.repo:containsi(${term})`).show();
    });

    let loadingRepos = false;
    const loadRepos = () => {
      const $holder = $('#repositories');
      const hasRepos = !$holder.find('ul').length;

      if (!loadingRepos && $holder.length && hasRepos) {
        loadingRepos = true;

        $holder.load('/repos', () => {
          loadingRepos = false;

          if ($holder.find('ul').length) {
            $('.search').show();
          }
        });
      }
    };

    setInterval(loadRepos, 2000);
    loadRepos();
  }
};
