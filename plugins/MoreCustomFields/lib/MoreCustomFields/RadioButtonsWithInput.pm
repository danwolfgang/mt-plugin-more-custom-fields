package MoreCustomFields::RadioButtonsWithInput;

use strict;

use MT 4.2;
use base qw(MT::Plugin);

sub _options_field {
    return q{
<div class="textarea-wrapper">
    <textarea name="options" id="options" class="text full-width"><mt:Var name="options" escape="html"></textarea>
</div>
<p class="hint">
    Please enter all allowable options for this field as a comma delimited list. The last option will have a text input option appended to it.
</p>
    };
}

sub _field_html {
    return q{
    <ul class="custom-field-radio-list">
<mt:Loop name="option_loop">
    <mt:If name="__last__">
        <li>
            <mt:Loop name="rbwi_input_loop">
                <mt:If name="field_id" like="$field_basename">
                    <mt:If name="field_input" like=":">
                        <mt:Var name="field_input" escape="html" regex_replace='/^(.+?:\s+)(.+?)/',"$2" setvar="input">
                    <mt:Else>
                        <mt:Var name="field_input" value="" setvar="input">
                    </mt:If>
                </mt:if>
            </mt:loop>
            <mt:SetVarBlock name="label"><mt:Var name="option" escape="html"></mt:SetVarBlock>
            <input type="hidden" name="<mt:Var name="field_name">_radiobuttonswithinput_beacon" value="<mt:Var name="label" escape="html" regex_replace="/^(.*?):","$1">" />
            <input type="radio" name="<mt:Var name="field_name">" value="<mt:Var name="label" escape="html" regex_replace="/^(.*?):","$1">" id="<mt:Var name="field_id">_<mt:Var name="__counter__">"<mt:if name="input"> checked="checked"</mt:if> class="rb" />
            <label for="<mt:Var name="field_id">_<mt:Var name="__counter__">">
                <mt:Var name="label" escape="html">
            </label>
            <input type="text"
                name="<mt:Var name="field_name">_radiobuttonswithinput"
                class="radiobuttonswithinput-input med"
                value="<mt:Var name="input" escape="html">" />
        </li>
    <mt:Else>
        <li>
            <input type="radio" name="<mt:Var name="field_name">" value="<mt:Var name="option" escape="html">" id="<mt:Var name="field_id">_<mt:Var name="__counter__">"<mt:if name="is_selected"> checked="checked"</mt:if> class="rb" />
            <label for="<mt:Var name="field_id">_<mt:Var name="__counter__">">
                <mt:Var name="option" escape="html">
            </label>
        </li>
    </mt:If>
</mt:Loop>
    </ul>
    };
}

sub _field_html_params {
    my ($key, $tmpl_key, $tmpl_param) = @_;
    my $app = MT->instance;

    my $id       = $app->param('id');
    my $blog     = $app->blog;
    my $blog_id  = $blog ? $blog->id : 0;
    my $obj_type = $tmpl_param->{obj_type};

    # Give up if there is no object type; we must be on the Edit Field
    # screen, where there's nothing to load anyway.
    return unless $obj_type;

    # Figure out what kind of object we're working with
    my @objects;
    if ($obj_type eq 'author') {
        @objects = MT::Author->load( { id => $id, } );
    }
    if ($obj_type eq 'category'){
        @objects = MT::Category->load( { id => $id, } );
    }
    if ($obj_type eq 'folder'){
        # For some reason, using MT::Folder doesn't work, and the class must be specified.
        @objects = MT::Category->load( { id    => $id,
                                         class => 'folder', } );
    }
    if ($obj_type eq 'entry'){
        @objects = MT::Entry->load( { id => $id, } );
    }
    if ($obj_type eq 'page'){
        # For some reason, using MT::Page doesn't work, and the class must be specified.
        @objects = MT::Entry->load( { id    => $id,
                                      class => 'page', } );
    }

    # Only one object should ever be returned (the current one)
    # So I shouldn't really *need* to do a loop here... right?
    foreach my $obj (@objects) {
        my @fields = CustomFields::Field->load( { obj_type => $obj_type,
        #Don't grab the blog_id because that keeps system-wide setting from working ok...
                                                  #blog_id  => $blog_id,
                                                  type     => 'radio_input',
                                                } );
        my @input_loop;
        foreach my $field (@fields) {
            my $basename = 'field.'.$field->basename;
            # Throw these into a loop. That way, if multiple instances of
            # the field are used, each gets the correct field and value.
            push @input_loop, { field_basename => $field->basename,
                                field_input    => $obj->$basename,
                              };
        }
        $tmpl_param->{rbwi_input_loop} = \@input_loop;
    }
}

# This is called by MoreCustomFields::Plugin::post_save, which is the 
# post-save callback handler. Save the data for this custom field type.
sub _save {
    my ($arg_ref) = shift;
    my $app            = $arg_ref->{app};
    my $obj            = $arg_ref->{object};
    my $field_basename = $arg_ref->{field_basename};

    my $field_name = 'customfield_' . $field_basename . '_radiobuttonswithinput';

    # This is the text input value
    my $input_value = $app->param($field_name);

    if ($input_value) {
        # The "beacon" is the name of the last field.
        my $selected = $app->param($field_name."_beacon");

        # This is the selected radio button
        my $customfield_value = $app->param('customfield_' . $field_basename);

        # Compare the beacon and selected value. Only if they match should the 
        # text input be saved.
        if ($selected eq $customfield_value) {
            $customfield_value .= ': '.$input_value;
        }

        $app->param('customfield_' . $field_basename, $customfield_value);
    }

    # Destroy the specially-assembled fields, because they make MT barf.
    $app->delete_param($field_name.'_beacon');
    $app->delete_param($field_name);
}
1;

__END__
