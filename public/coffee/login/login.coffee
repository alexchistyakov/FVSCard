$ ->
  $(".popup .form").submit (e) ->
    e.preventDefault()
    e.stopPropagation()

    form = $ @

    $.post $(@).attr("action"), $(@).serialize(),  (response) ->
      unless response.success
        form.find(".error-message").eq(0).html response.message
      else
        window.location.href = response.redirect

