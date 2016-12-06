import $ from 'jquery';
import {addCSRFField} from '../libs/forms';

$.extend($.expr[':'], {
  containsi: (elem, i, match) =>
    (elem.textContent || elem.innerText || '').toLowerCase()
    .indexOf((match[3] || '').toLowerCase()) >= 0
});

const behaviors = {
  init: () => {
    behaviors.loadData();
    $(document).on('click', 'button.expand', behaviors.expandBehavior);
    $(document).on('input', 'input.search', behaviors.filterBehaviors);
    $(document).on('change', '.content input', behaviors.saveSettings);
    $(document).on('change', '.content select', behaviors.saveSettings);
  },

  filterBehaviors: (ev) => {
    const term = $(ev.currentTarget).val();
    $('li.behavior').hide();
    $(`li.behavior:containsi(${term})`).show();
  },

  loadData: () => {
    // find inputs with sources
    $('input, select').each((index, element) => {
      const source = $(element).attr('data-source');
      if (!source) return null;

      switch (source) {
        case 'labels':
          return behaviors.loadLabels(element);
        case 'teams':
          return behaviors.loadTeams(element);
        default:
          console.warn(`Data source (${source}) does not exist`);
          return null;
      }
    });
  },

  loadLabels: (element) => {
    $.ajax({
      type: 'GET',
      url: `${window.location.href}/labels`,
      success: (data) => {
        // initial value is stored in a hidden field
        const name = $(element).attr('name').replace(/\[\]/, '');
        const value = $(`input[name=${name}]`).val();

        $.each(data.labels, (key, label) => {
          $(element)
          .append($('<option></option>')
          .attr('value', label.id)
          .attr('selected', value === label.id.toString() ? true : undefined)
          .text(label.name));
        });
      }
    });
  },

  loadTeams: (element) => {
    $.ajax({
      type: 'GET',
      url: `${window.location.href}/teams`,
      success: (data) => {
        // initial value is stored in a hidden field
        const name = $(element).attr('name').replace(/\[\]/, '');
        const value = $(`input[name=${name}]`).val();

        $.each(data.teams, (key, team) => {
          $(element)
          .append($('<option></option>')
          .attr('value', team.id)
          .attr('selected', value === team.id.toString() ? true : undefined)
          .text(team.name));
        });
      }
    });
  },

  saveSettings: (ev) => {
    const $form = $(ev.currentTarget).parents('form');
    addCSRFField($form);

    $.ajax({
      type: $form.attr('method'),
      url: $form.attr('action'),
      data: $form.serialize(),
      success: () => {
        //
      }
    });
  },

  expandBehavior: (ev) => {
    ev.preventDefault();

    // open the one we clicked
    $(ev.currentTarget)
    .parents('.behavior')
    .find('.content')
    .fadeToggle();
  }
};

export default behaviors;
