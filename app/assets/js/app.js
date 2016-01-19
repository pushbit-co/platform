$(function(){
  document.cookie = 'timezone='+jstz.determine().name()+';';

  if (window.USER) {
    var handler = StripeCheckout.configure({
      key: window.STRIPE_PUBLISHABLE_KEY,
      image: 'https://s3.amazonaws.com/stripe-uploads/acct_17FbXPKOnaks6VJBmerchant-icon-1450654427617-bot.png',
      locale: 'auto',
      email: window.USER.email,
      allowRememberMe: false
    });
  }

  // process card details into stripe token if needed
  $(document).on('submit', '.subscribe', function(ev) {
    var $form = $(this);
    var data = $form.serializeObject();
    var priv = (data.private == "true");
    
    if (priv && !data.has_customer && !data.token) {
      handler.open({
        name: 'Pushbit',
        description: data.name,
        panelLabel: 'Subscribe',
        amount: 1500,
        token: function(token) {
          // add the payment token and resubmit as we now have the neccessaries
          $form.find('input[name=token]').val(token.id);
          $form.submit();
        }
      });
      ev.preventDefault();
    } else {
      $form.find('button')
        .text("Subscribing...")
        .attr('disabled', true);
    }
  });

  // closes Stripe checkout on page unload
  $(window).on('popstate', function() {
    handler.close();
  });

  $(document).on('submit', 'form', function(){
    var $form   = $(this);
    var method = $form.attr('method').toUpperCase();
    var token  = $('meta[name=csrf-token]').attr('content');

    // add the CSRF token as a hidden input to the form
    if (method && method !== 'GET') {
      $form.prepend($('<input>', {name: '_csrf', type: 'hidden', value: token}));
    }
  });

  $('body').on('change', 'input:radio', function(){
    $(this).parents('li').addClass('checked');
    $('input:radio:not(:checked)').parents('li').removeClass('checked');
  });

  $('body').on('click', '#subscribe .organizations input', function(){
    var organization = $(this).val();

    if (organization) {
      $('li.repo').hide();
      $('li.repo.owner-' + organization).show();
    } else {
      $('li.repo').show();
    }
  });

  $('#search').on('input', function() {
    var term = $(this).val();
    $('li.repo').hide();
    $('li.repo:containsi('+ term +')').show();
  });

  var loadingRepos = false;
  var loadRepos = function(){
    var $holder = $("#repositories");
    var hasRepos = !$holder.find('ul').length;

    if(!loadingRepos && $holder.length && hasRepos) {
      loadingRepos = true;

      $holder.load("/repos", function(){
        loadingRepos = false;
        
        if ($holder.find('ul').length) {
          $('.search').show();
        }
      });
    }
  };

  setInterval(loadRepos, 2000);
  loadRepos();

  $.extend($.expr[':'], {
    'containsi': function(elem, i, match, array){
      return (elem.textContent || elem.innerText || '').toLowerCase()
      .indexOf((match[3] || "").toLowerCase()) >= 0;
    }
  });
  
  $.fn.serializeObject = function(){
    var o = {};
    var a = this.serializeArray();
    $.each(a, function() {
      if (o[this.name] !== undefined) {
        if (!o[this.name].push) {
          o[this.name] = [o[this.name]];
        }
        o[this.name].push(this.value || '');
      } else {
        o[this.name] = this.value || '';
      }
    });
    return o;
  };

  if ($('#dashboard').length) {
    $('#dashboard #overview .nav-tabs a').click(function (e) {
      e.preventDefault()
      $(this).tab('show')
    });

    var id = $('#dashboard').data('repo-id');
    if (id) {
      $('#actions').load("/repos/"+id+"/actions");
      $('#tasks').load("/repos/"+id+"/tasks");
    } else {
      $('#actions').load("/actions");
      $('#tasks').load("/tasks");
    }
  }

  $("#search").on('keydown', function(ev){
    if (event.keyCode == 13) {
      ev.preventDefault();
      return false;
    }
  });
});
