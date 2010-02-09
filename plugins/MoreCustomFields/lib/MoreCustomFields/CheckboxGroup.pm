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
    <textarea name="options" id="options" class="full-width"><mt:Var name="options" escape="html"></textarea>
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

1;

__END__
