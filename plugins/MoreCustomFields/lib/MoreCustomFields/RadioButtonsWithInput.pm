package MoreCustomFields::RadioButtonsWithInput;

use strict;

use MT 4.2;
use base qw(MT::Plugin);
use CustomFields::Util qw( get_meta save_meta field_loop _get_html );
use MT::Util
  qw( relative_date offset_time offset_time_list epoch2ts ts2epoch format_ts encode_html dirify );

sub _options_field {
    return q{
<div class="textarea-wrapper">
    <textarea name="options" id="options" class="full-width"><mt:Var name="options" escape="html"></textarea>
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
            <input type="text" name="<mt:Var name="field_name">_radiobuttonswithinput" style="border: 1px solid #ccc; margin-left: 5px;" value="<mt:Var name="input" escape="html">" />
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

1;

__END__
