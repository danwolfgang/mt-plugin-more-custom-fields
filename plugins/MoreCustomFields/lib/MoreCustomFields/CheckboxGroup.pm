package MoreCustomFields::CheckboxGroup;

use strict;

use MT 4.2;
use base qw(MT::Plugin);
use CustomFields::Util qw( get_meta save_meta field_loop _get_html );
use MT::Util
  qw( relative_date offset_time offset_time_list epoch2ts ts2epoch format_ts encode_html dirify );

sub _options_field {
    return q{
<div class="textarea-wrapper">
    <textarea name="options" id="options" class="text full-width"><mt:Var name="options" escape="html"></textarea>
</div>
<p class="hint">
    Please enter all allowable options for this field as a comma delimited list.
</p>
    };
}

sub _field_html {
    return q{
    <ul class="custom-field-radio-list">
<mt:Loop name="option_loop">
    <mt:If name="option">
        <li>
            <mt:SetVarBlock name="optiontest"><mt:Var name="option"></mt:SetVarBlock>
            <input type="hidden" name="<mt:Var name="field_name">_checkboxgroupcf_<mt:Var name="__counter__">_cb_beacon" value="1" />
            <input type="checkbox" name="<mt:Var name="field_name">_checkboxgroupcf_<mt:Var name="__counter__">" value="<mt:Var name="option" escape="HTML">" id="<mt:Var name="field_id">_<mt:Var name="__counter__">"<mt:if name="field_value" like="$optiontest"> checked="checked"</mt:if> class="cb" />
            <label for="<mt:Var name="field_id">_<mt:Var name="__counter__">">
                <mt:Var name="option">
            </label>
        </li>
    </mt:If>
</mt:Loop>
    </ul>
    };
}

# This is called by MoreCustomFields::Plugin::post_save, which is the 
# post-save callback handler. Save the data for this custom field type.
sub _save {
    my ($arg_ref) = shift;
    my $app   = $arg_ref->{app};
    my $obj   = $arg_ref->{object};
    my $count = $arg_ref->{count};

    # Now look at the individual checkbox in the group to determine if 
    # it's checked.
    if( $app->param( /^customfield_(.*?)_checkboxgroupcf_$count$/ ) ) { 
        my $field_name = "customfield_$1_checkboxgroupcf_$count";

        # This line serves two purposes:
        # - Create the "real" customfield to write to the DB, if it doesn't 
        #   exist already.
        # - If the field has already been created (because this is the 2nd or 
        #   3rd or 4th etc Checkbox Group CF option) then get it so that we 
        #   can see the currently-selected options and append a new result to 
        #   them.
        my $customfield_value = $app->param("customfield_$1");

        # Join all the checkboxes into a list, but only if the field has 
        # already been set
        my $result;
        if ( $customfield_value ) {
            $result = join ', ', $customfield_value, $app->param($field_name);
        }
        else { # Nothing saved yet? Just assign the variable
            $result = $app->param($field_name);
        }

        # If the customfield held some results, then a real text value exists,
        # such as "blue." If the field was empty, however, the $results 
        # variable is empty, indicating that the field should *not* be saved. 
        # This is incorrect because an empty field may be purposefully 
        # unselected, so we need to force save the deletion of the field.
        if (!$result) { $result = ' '; }

        # Save the new result to the *real* field name, which should be 
        # written to the DB.
        $app->param("customfield_$1", $result);

        # Destory the specially-assembled fields, because they make MT barf.
        $app->delete_param($field_name);
        $app->delete_param($field_name.'_cb_beacon');
    }
}

1;

__END__
