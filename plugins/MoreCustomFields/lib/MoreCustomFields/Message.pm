package MoreCustomFields::Message;

use strict;

use MT 4.2;
use base qw(MT::Plugin);
use CustomFields::Util qw( get_meta save_meta field_loop _get_html );
use MT::Util
  qw( relative_date offset_time offset_time_list epoch2ts ts2epoch format_ts encode_html dirify );

sub _options_field {
    return q{
<p>
    <input type="radio" name="options" id="options_allow" class="radio" value="allow"<mt:If name="options" eq="allow"> checked="checked"</mt:If> />
    <label for="options_allow">Allow Blog Administrators and System Administrators to edit this field.</label>
</p>
<p>
    <input type="radio" name="options" id="options_deny" class="radio" value="deny"<mt:If name="options" eq="deny"> checked="checked"</mt:If> />
    <label for="options_deny">Allow <em>no</em> users to edit this field (the contents may only be edited here).</label>
</p>
    };
}

sub _field_html {
    # It appears that the Message custom field hits upon a weird bug, 
    # brought on by the combination of logic used here and the need to edit
    # the default text. The returned HTML can't begin with an MT tag--it 
    # it must begin with HTML. So, I've just added this simple HTML comment
    # below, just to make it work.
    return q{
<!-- Building the Message custom field type -->
<mt:SetVarBlock name="message_cf">
    <div class="textarea-wrapper">
        <textarea name="<mt:var name="field_name">"
            id="<mt:var name="field_id">"
            class="text full-width ta"
            rows="3"
            cols="72"><mt:var name="field_value" escape="html"></textarea>
    </div>
</mt:SetVarBlock>

<mt:if name="is_admin">
    <mt:Ignore> If admins are allowed to edit the field... </mt:Ignore>
    <mt:If name="options" eq="allow">
        <mt:Var name="message_cf">
    </mt:If>

    <mt:Ignore> If *nobody* is allowed to edit the field... </mt:Ignore>
    <mt:If name="options" eq="deny">
        <mt:If name="on_edit_field">
            <mt:Ignore> 
                However the admin should always be able to edit the field
                on the Edit Field screen.
            </mt:Ignore>
            <mt:Var name="message_cf">
        <mt:Else>
            <mt:Var name="field_value" filters="__default__">
        </mt:If>
    </mt:If>

<mt:Else>
    <mt:Ignore>
        By not supplying the field_id or textarea as a hidden field, the
        text is simply displayed. When saved, no custom field data is ever
        actually saved. That means the "default" message can be changed at
        any time and it will be updated anywhere it's displayed.
    </mt:Ignore>
    <mt:Var name="field_value" filters="__default__">
</mt:If>
    };
}

sub _field_html_params {
    my ($key, $tmpl_key, $tmpl_param) = @_;
    my $app = MT->instance;

    # Use this is_admin variable to test whether the current user is an 
    # admin. We can't just use the is_administrator variable because it's
    # not actually set everywhere. In particular, on the Create/Edit Custom
    # Field screen, where the admin can set the default text,
    # is_administrator isn't set.
    if ($app->user) {
        $tmpl_param->{is_admin} = $app->user->is_superuser();
    }
    
    # If the user is on the Edit Field screen, we want them to be able to 
    # edit the field contents regardless of the option selection.
    if ($app->mode eq 'view' && $app->param('_type') eq 'field') {
        $tmpl_param->{on_edit_field} = 1;
    }
}

1;

__END__
