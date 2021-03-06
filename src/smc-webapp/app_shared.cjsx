##############################################################################
#
#    CoCalc: Collaborative Calculation in the Cloud
#
#    Copyright (C) 2016 -- 2017, Sagemath Inc.
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
###############################################################################

{React, ReactDOM, rclass, redux, rtypes, Redux, Actions, Store, COLOR} = require('./smc-react')
{Button, Col, Row, Modal, NavItem} = require('react-bootstrap')
{Icon, Space, Tip} = require('./r_misc')
{COLORS} = require('smc-util/theme')
{webapp_client} = require('./webapp_client')
misc = require('smc-util/misc')

{HelpPage} = require('./r_help')
{ProjectsPage} = require('./projects')
{ProjectPage, MobileProjectPage} = require('./project_page')
{AccountPage} = require('./account_page')
{FileUsePage} = require('./file_use')

ACTIVE_BG_COLOR = COLORS.TOP_BAR.ACTIVE
feature = require('./feature')

exports.ActiveAppContent = ({active_top_tab, render_small}) ->
    switch active_top_tab
        when 'projects'
            return <ProjectsPage />
        when 'account'
            return <AccountPage />
        when 'about'
            return <HelpPage />
        when 'help'
            return <div>To be implemented</div>
        when 'file-use'
            return <FileUsePage redux={redux} />
        when undefined
            return
        else
            project_name = redux.getProjectStore(active_top_tab).name
            if render_small
                <MobileProjectPage name={project_name} project_id={active_top_tab} />
            else
                <ProjectPage name={project_name} project_id={active_top_tab} />

exports.NavTab = rclass
    displayName : "NavTab"

    propTypes :
        label           : rtypes.string
        label_class     : rtypes.string
        icon            : rtypes.string
        close           : rtypes.bool
        on_click        : rtypes.func
        active_top_tab  : rtypes.string
        actions         : rtypes.object
        style           : rtypes.object
        inner_style     : rtypes.object
        add_inner_style : rtypes.object

    shouldComponentUpdate: (next) ->
        if @props.children?
            return true
        return misc.is_different(@props, next, ['label', 'label_class', 'icon', 'close', 'active_top_tab'])

    render_label: ->
        if @props.label?
            <span style={marginLeft: 5} className={@props.label_class}>
                {@props.label}
            </span>

    make_icon: ->
        if @props.icon?
            <Icon
                name  = {@props.icon}
                style = {fontSize: 20, paddingRight: 2}
            />

    on_click: (e) ->
        if @props.name?
            @actions('page').set_active_tab(@props.name)
        @props.on_click?()

    render: ->
        is_active = @props.active_top_tab == @props.name

        if @props.style?
            outer_style = @props.style
        else
            outer_style = {}

        outer_style.float = 'left'

        outer_style.fontSize ?= '14px'
        outer_style.cursor ?= 'pointer'
        outer_style.border = 'none'

        if is_active
            outer_style.backgroundColor = ACTIVE_BG_COLOR

        if @props.inner_style
            inner_style = @props.inner_style
        else
            inner_style =
                padding : '10px'
        if @props.add_inner_style
            misc.merge(inner_style, @props.add_inner_style)

        <NavItem
            active = {is_active}
            onClick = {@on_click}
            style = {outer_style}
        >
            <div style={inner_style}>
                {@make_icon()}
                {@render_label()}
                {@props.children}
            </div>
        </NavItem>

exports.NotificationBell = rclass
    displayName: 'NotificationBell'

    propTypes :
        count    : rtypes.number
        active   : rtypes.bool
        on_click : rtypes.func

    getDefaultProps: ->
        active : false

    shouldComponentUpdate: (next) ->
        return misc.is_different(@props, next, ['count', 'active'])

    on_click: (e) ->
        @actions('page').toggle_show_file_use()
        document.activeElement.blur() # otherwise, it'll be highlighted even when closed again
        @props.on_click?()

    notification_count: ->
        count_styles =
            fontSize   : '10pt'
            color      : COLOR.FG_RED
            position   : 'absolute'
            left       : '16px'
            top        : '11px'
            fontWeight : 700
            background : 'transparent'
        if @props.count > 9
            count_styles.left         = '15.8px'
            count_styles.background   = COLORS.GRAY_L
            count_styles.borderRadius = '50%'
            count_styles.border       = '2px solid lightgrey'
        if @props.count > 0
            <span style={count_styles}>{@props.count}</span>

    render: ->
        outer_style =
            position    : 'relative'
            float       : 'left'

        if @props.active
            outer_style.backgroundColor = ACTIVE_BG_COLOR

        inner_style =
            padding  : '10px'
            fontSize : '17pt'
            cursor   : 'pointer'

        clz = ''
        bell_style = {}
        if @props.count > 0
            clz = 'smc-bell-notification'
            bell_style = {color: COLOR.FG_RED}

        <NavItem
            ref       = {'bell'}
            style     = {outer_style}
            onClick   = {@on_click}
            className = {'active' if @props.active}
        >
            <div style={inner_style}>
                <Icon name='bell-o' className={clz} style={bell_style} />
                {@notification_count()}
            </div>
        </NavItem>

exports.ConnectionIndicator = rclass
    displayName : 'ConnectionIndicator'

    propTypes :
        actions  : rtypes.object
        ping     : rtypes.number
        status   : rtypes.string
        on_click : rtypes.func

    reduxProps :
        page :
            avgping           : rtypes.number
            connection_status : rtypes.string
        account :
            mesg_info         : rtypes.immutable.Map

    shouldComponentUpdate: (next) ->
        return misc.is_different(@props, next, ['avgping', 'connection_status', 'ping', 'status', 'mesg_info'])

    render_ping: ->
        if @props.avgping?
            <Tip
                title     = {'Most recently recorded roundtrip time to the server.'}
                placement = {'left'}
                stable    = {true}
                >
                {Math.floor(@props.avgping)}ms
            </Tip>

    render_connection_status: ->
        if @props.connection_status == 'connected'
            icon_style = {marginRight: 8, fontSize: '13pt', display: 'inline'}
            if (@props.mesg_info?.get('enqueued') ? 0) > 5  # serious backlog of data!
                icon_style.color = 'red'
            else if (@props.mesg_info?.get('count') ? 0) > 1 # worrisome amount
                icon_style.color = '#08e'
            else if (@props.mesg_info?.get('count') ? 0) > 0 # working well but doing something minimal
                icon_style.color = '#00c'
            else
                icon_style.color = 'grey'
            <div>
                <Icon name='wifi' style={icon_style}/>
                {@render_ping()}
            </div>
        else if @props.connection_status == 'connecting'
            <span style={backgroundColor : '#FFA500', color : 'white', padding : '1ex', 'zIndex': 100001}>
                connecting...
            </span>
        else if @props.connection_status == 'disconnected'
            <span style={backgroundColor : '#FFA500', color : 'white', padding : '1ex', 'zIndex': 100001}>
                disconnected
            </span>

    connection_click: ->
        @props.actions.show_connection(true)
        @props.on_click?()
        document.activeElement.blur() # otherwise, it'll be highlighted even when closed again

    render: ->
        outer_styles =
            width      : '8.5em'
            color      : '#666'
            fontSize   : '10pt'
            lineHeight : '10pt'
            cursor     : 'pointer'
            float      : 'left'
        inner_styles =
            padding : '13.5px'

        <NavItem style={outer_styles} onClick={@connection_click}>
            <div style={inner_styles} >
                {@render_connection_status()}
            </div>
        </NavItem>

bytes_to_str = (bytes) ->
    x = Math.round(bytes / 1000)
    if x < 1000
        return x + "K"
    return x/1000 + "M"


MessageInfo = rclass
    propTypes :
        info : rtypes.immutable.Map

    render: ->
        if not @props.info?
            return <span></span>
        if @props.info.get('count') > 0
            flight_style = {color:'#08e', fontWeight:'bold'}
        <div>
            <pre>
                {@props.info.get('sent')} messages sent ({bytes_to_str(@props.info.get('sent_length'))})
                <br/>
                {@props.info.get('recv')} messages received ({bytes_to_str(@props.info.get('recv_length'))})
                <br/>
                <span style={flight_style}>{@props.info.get('count')} messages in flight</span>
                <br/>
                {@props.info.get('enqueued')} messages queued to send
            </pre>
            <div style={color:"#666"}>
                Connection icon color changes as the number of messages increases. Usually, no action is needed, but the counts are helpful for diagnostic purposes or to help you understand what is going on.  The maximum number of messages that can be sent at the same time is {@props.info.get('max_concurrent')}.
            </div>
        </div>

exports.ConnectionInfo = rclass
    displayName : 'ConnectionInfo'

    propTypes :
        actions : rtypes.object
        ping    : rtypes.number
        avgping : rtypes.number
        status  : rtypes.string

    reduxProps :
        account :
            hub       : rtypes.string
            mesg_info : rtypes.immutable.Map

    shouldComponentUpdate: (next) ->
        return misc.is_different(@props, next, ['avgping', 'ping', 'status', 'hub', 'mesg_info'])

    close: ->
        @actions('page').show_connection(false)

    connection_body: ->
        <div>
            {<Row>
                <Col sm={3}>
                    <h4>Ping time</h4>
                </Col>
                <Col sm={6}>
                    <pre>{@props.avgping}ms (latest: {@props.ping}ms)</pre>
                </Col>
            </Row> if @props.ping}
            <Row>
                <Col sm={3}>
                    <h4>Hub server</h4>
                </Col>
                <Col sm={6}>
                    <pre>{if @props.hub? then @props.hub else "Not signed in"}</pre>
                </Col>
                <Col sm={2} smOffset={1}>
                    <Button bsStyle='warning' onClick={=>webapp_client._fix_connection(true)}>
                        <Icon name='repeat' spin={@props.status == 'connecting'} /> Reconnect
                    </Button>
                </Col>
            </Row>
            <Row>
                <Col sm={3}>
                    <h4>Messages</h4>
                </Col>
                <Col sm={6}>
                    <MessageInfo info={@props.mesg_info} />
                </Col>
            </Row>
        </div>

    render: ->
        <Modal bsSize={"large"}  show={true} onHide={@close} animation={false}>
            <Modal.Header closeButton>
                <Modal.Title>
                    <Icon name='wifi' style={marginRight: '1em'} /> Connection
                </Modal.Title>
            </Modal.Header>
            <Modal.Body>
                {@connection_body()}
            </Modal.Body>
            <Modal.Footer>
                <Button onClick={@close}>Close</Button>
            </Modal.Footer>
        </Modal>

exports.FullscreenButton = rclass
    displayName : 'FullscreenButton'

    reduxProps :
        page :
            fullscreen : rtypes.oneOf(['default', 'kiosk'])

    shouldComponentUpdate: (next) ->
        return @props.fullscreen != next.fullscreen

    on_fullscreen: (ev) ->
        if ev.shiftKey
            @actions('page').set_fullscreen('kiosk')
        else
            @actions('page').toggle_fullscreen()

    render: ->
        icon = if @props.fullscreen then 'compress' else 'expand'

        tip_style =
            position   : 'fixed'
            zIndex     : 10000
            right      : 0
            top        : '1px'
            borderRadius: '3px'


        icon_style =
            fontSize   : '13pt'
            padding    : 4
            color      : COLORS.GRAY
            cursor     : 'pointer'

        if @props.fullscreen
            icon_style.background = '#fff'
            icon_style.opacity    = .7
            icon_style.border     = '1px solid grey'

        <Tip
            style     = {tip_style}
            title     = {'Removes navigational chrome from the UI. Shift-click to enter "kiosk-mode".'}
            placement = {'left'}
        >
            <Icon
                style   = {icon_style}
                name    = {icon}
                onClick = {@on_fullscreen}
            />
        </Tip>

exports.AppLogo = rclass
    displayName : 'AppLogo'

    shouldComponentUpdate: ->
        return false

    render: ->
        {APP_ICON} = require('./art')
        styles =
            display         : 'inline-block'
            backgroundImage : "url('#{APP_ICON}')"
            backgroundSize  : 'contain'
            backgroundRepeat: 'no-repeat'
            height          : 36
            width           : 36
            position        : 'relative'
            margin          : '2px'
        <div style={styles}></div>

exports.VersionWarning = rclass
    displayName : 'VersionWarning'

    propTypes :
        new_version : rtypes.immutable.Map

    shouldComponentUpdate: (props) ->
        return @props.new_version != props.new_version

    render_critical: ->
        if @props.new_version.get('min_version') > webapp_client.version()
            <div>
                <br />
                THIS IS A CRITICAL UPDATE. YOU MUST <Space/>
                <a onClick={=>window.location.reload()} style={cursor:'pointer', color: 'white', fontWeight: 'bold', textDecoration: 'underline'}>
                    RELOAD THIS PAGE
                </a>
                <Space/> IMMEDIATELY OR YOU WILL BE DISCONNECTED.  Sorry for the inconvenience.
            </div>

    render_close: ->
        if not (@props.new_version.get('min_version') > webapp_client.version())
            <Icon
                name = 'times'
                className = 'pull-right'
                style = {cursor : 'pointer'}
                onClick = {=>redux.getActions('page').set_new_version(undefined)} />

    render: ->
        styles =
            fontSize        : '12pt'
            position        : 'fixed'
            left            : 12
            backgroundColor : '#fcf8e3'
            color           : '#8a6d3b'
            top             : 20
            borderRadius    : 4
            padding         : '15px'
            zIndex          : 900
            boxShadow       : '8px 8px 4px #888'
            width           : '70%'
            marginTop       : '1em'
        if @props.new_version.get('min_version') > webapp_client.version()
            styles.backgroundColor = 'red'
            styles.color           = '#fff'

        <div style={styles}>
            <Icon name={'refresh'} /> New Version Available: upgrade by  <Space/>
            <a onClick={=>window.location.reload()} style={cursor:'pointer', fontWeight: 'bold', color:styles.color, textDecoration: 'underline'}>
                reloading this page
            </a>.
            {@render_close()}
            {@render_critical()}
        </div>

warning_styles =
    position        : 'fixed'
    left            : 12
    backgroundColor : 'red'
    color           : '#fff'
    top             : 20
    opacity         : .9
    borderRadius    : 4
    padding         : 5
    marginTop       : '1em'
    zIndex          : 100000
    boxShadow       : '8px 8px 4px #888'
    width           : '70%'

exports.CookieWarning = rclass
    displayName : 'CookieWarning'

    render: ->
        <div style={warning_styles}>
            <Icon name='warning' /> You <em>must</em> enable cookies to sign into CoCalc.
        </div>

misc = require('smc-util/misc')
storage_warning_style = misc.copy(warning_styles)
storage_warning_style.top = 55

exports.LocalStorageWarning = rclass
    displayName : 'LocalStorageWarning'

    render: ->
        <div style={storage_warning_style}>
            <Icon name='warning' /> You <em>must</em> enable local storage to use this website{' (on Safari you must disable private browsing mode)' if feature.get_browser() == 'safari'}.
        </div>

# This is used in the "desktop_app" to show a global announcement on top of CoCalc.
# It was first used for a general CoCalc announcement, but it's general enough to be used later on
# for other global announcements.
# For now, it just has a simple dismiss button backed by the account → other_settings, though.
# 20171013: disabled, see https://github.com/sagemathinc/cocalc/issues/1982
exports.GlobalInformationMessage = rclass
    displayName: 'GlobalInformationMessage'

    dismiss: ->
        redux.getTable('account').set(other_settings:{show_global_info2:webapp_client.server_time()})

    render: ->
        more_url = 'https://github.com/sagemathinc/cocalc/wiki/KubernetesMigration'
        bgcol = COLORS.YELL_L
        style =
            padding         : '5px 0 5px 5px'
            backgroundColor : bgcol
            fontSize        : '18px'
            position        : 'fixed'
            zIndex          : '101'
            right           : 0
            left            : 0
            height          : '40px'

        <Row style={style}>
            <Col sm={9} style={paddingTop: 3}>
                <p><b>CoCalc <a target='_blank' href={more_url}>migrated to Kubernetes</a></b>.
                {' '}Please report any issues.
                {' '}<a target='_blank' href={more_url}>More information...</a></p>
            </Col>
            <Col sm={3}>
                <Button bsStyle='danger' bsSize="small" className='pull-right' style={marginRight:'20px'}
                    onClick={@dismiss}>Close</Button>
            </Col>
        </Row>
