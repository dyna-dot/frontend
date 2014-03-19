CI.outer.Page = class Page
  constructor: (@name, @_title, @mixpanelID=null, @opts={}) ->

  display: (cx) =>
    @setPageTitle(cx)

    @maybeTrackMixpanel()

    # Render content
    @render(cx)

    # Land at the right anchor on the page
    @scroll window.location.hash

    # Fetch page-specific libraries
    @placeholder()
    @follow()
    @lib() if @lib?

    ko.applyBindings(VM)

  maybeTrackMixpanel: () =>
    if @mixpanelID?
      mixpanel.track @mixpanelID

  viewContext: (cx) =>
    {}

  render: (cx) =>
    template = @name
    klass = "outer"

    args = $.extend renderContext, @viewContext(cx)
    header =
      $("<header></header>")
        .append(HAML.header(args))

    content =
      $("<main></main>")
        .attr("id", "#{@name}-page")
        .append(HAML[template](args))

    footer =
      $("<footer></footer>")
        .append(HAML["footer"](args))


    $('#app')
      .html("")
      .removeClass('outer')
      .removeClass('inner')
      .addClass(klass)
      .append(header)
      .append(content)
      .append(footer)

    if VM.ab().old_font()
      $('#app').addClass('old-font')

    if @opts.addLinkTargets == true
      console.log("Page:", @name, "adding link targets")
      @addLinkTargets()

  scroll: (hash) =>
    if hash == '' or hash == '#' then hash = "body"
    if $(hash).offset()
      $('html, body').animate({scrollTop: $(hash).offset().top}, 0)

  title: =>
    @_title

  setPageTitle: (cx) =>
    document.title = @title(cx) + " - CircleCI"

  placeholder: () =>
    $("input, textarea").placeholder()

  follow: =>
    $("#twitter-follow-template-div").empty()
    clone = $(".twitter-follow-template").clone()
    clone.removeAttr "style" # unhide the clone
    clone.attr "data-show-count", "false"
    clone.attr "class", "twitter-follow-button"
    $("#twitter-follow-template-div").append clone

    # reload twitter scripts to force them to run, converting a to iframe
    $.getScript "//platform.twitter.com/widgets.js"

  addLinkTargets: =>
    # Add a link target to every heading. If there's an existing id, it won't override it
    h = ".content"
    headings = $("#{h} h2, #{h} h3, #{h} h4, #{h} h5, #{h} h6")
    console.log(headings.length, "headings found")
    for heading in headings
      @addLinkTarget heading

  addLinkTarget: (heading) =>
    jqh = $(heading)
    title = jqh.text()
    id = jqh.attr("id")

    if not id?
      id = title.toLowerCase()
      id = id.replace(/^\s+/g, '').replace(/\s+$/g, '') # strip whitespace
      id = id.replace(/\'/, '') # heroku's -> herokus
      id = id.replace(/[^a-z0-9]+/g, '-') # dashes everywhere
      id = id.replace(/^-/, '').replace(/-$/, '') # dont let first and last chars be dashes

    jqh.html("<a href='##{id}'>#{title}</a>").attr("id", id)
