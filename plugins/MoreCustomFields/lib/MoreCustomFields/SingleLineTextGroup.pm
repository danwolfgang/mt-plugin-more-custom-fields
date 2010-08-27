package MoreCustomFields::SingleLineTextGroup;

use strict;

use MT 4.2;
use base qw(MT::Plugin);
use CustomFields::Util qw( get_meta save_meta field_loop _get_html );
use MT::Util qw( relative_date offset_time offset_time_list epoch2ts ts2epoch format_ts encode_html dirify );

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
<mt:Loop name="option_loop">
    <mt:If name="__first__">
    <ul class="cf-text-group">
    </mt:If>
    <mt:If name="option">
        <li style="padding-bottom: 2px;">
            <input type="hidden" name="<mt:Var name="field_name">_singlelinetextgroupcf_<mt:Var name="option" dirify="1">_cb_beacon" value="1" />
            <label for="<mt:var name="field_name">_singlelinetextgroupcf_<mt:Var name="option" dirify="1">" style="width: 100px; display: block; float: left; text-align: right; padding: 4px 5px 0 0;"><mt:Var name="option"></label>
            <input type="text" name="<mt:var name="field_name">_singlelinetextgroupcf_<mt:Var name="option" dirify="1">" id="<mt:var name="field_name">_singlelinetextgroupcf_<mt:Var name="option" dirify="1">" value="<mt:Var name="value" escape="html">" class="ti" style="border:1px solid #ccc;background-color:#fff;padding:2px 4px; width: 465px;" />
        </li>
    </mt:If>
    <mt:If name="__last__">
    </ul>
    </mt:If>
</mt:Loop>
    };
}

sub _multi_field_html {
    return q{
<mt:SetVarTemplate name="invisible_field_template">
    <li style="padding-bottom: 2px;">
        <input type="hidden" name="<mt:Var name="field_name">_multiusesinglelinetextgroupcf_<mt:Var name="option" dirify="1">_cb_beacon" value="1" />
        <label for="<mt:var name="field_name">_multiusesinglelinetextgroupcf_<mt:Var name="option" dirify="1">" style="width: 100px; display: block; float: left; text-align: right; padding: 4px 5px 0 0;"><mt:Var name="option"></label>
        <input type="text" name="<mt:var name="field_name">_multiusesinglelinetextgroupcf_<mt:Var name="option" dirify="1">_invisible" id="<mt:var name="field_name">_multiusesinglelinetextgroupcf_<mt:Var name="option" dirify="1">" value="" class="ti" style="border:1px solid #ccc;background-color:#fff;padding:2px 4px; width: 465px;" />
    </li>
</mt:SetVarTemplate>
<mt:SetVarTemplate name="field_template">
    <li style="padding-bottom: 2px;">
        <input type="hidden" name="<mt:Var name="field_name">_multiusesinglelinetextgroupcf_<mt:Var name="option" dirify="1">_cb_beacon" value="1" />
        <label for="<mt:var name="field_name">_multiusesinglelinetextgroupcf_<mt:Var name="option" dirify="1">" style="width: 100px; display: block; float: left; text-align: right; padding: 4px 5px 0 0;"><mt:Var name="option"></label>
        <input type="text" name="<mt:var name="field_name">_multiusesinglelinetextgroupcf_<mt:Var name="option" dirify="1">" id="<mt:var name="field_name">_multiusesinglelinetextgroupcf_<mt:Var name="option" dirify="1">" value="<mt:Var name="value" escape="html">" class="ti" style="border:1px solid #ccc;background-color:#fff;padding:2px 4px; width: 465px;" />
    </li>
</mt:SetVarTemplate>

    <script type="text/javascript">
    function addGroup(parent,field_name) {
        var num = $('#' + parent + ' ul').size();
        $('#'+field_name+'_multiusesinglelinetextgroupcf_invisible-field').clone().appendTo('#' + parent);
        // Switch to display:block so that the field is visible.
        $('#' + parent + ' .cf-text-group').css('display', 'block');
        // The text input field has "_invisible" appended so that it isn't
        // inadvertently saved. Remove that trailing identifier so that the
        // field can be properly used.
        $('#' + parent + ' ul.cf-text-group input[type=text]').each(function(index) {
            var name = $(this).attr('name');
            name = name.replace(/_invisible$/, '');
            var name = $(this).attr('name', name);
        });
    }
    $(document).ready(function() {
        $('li.cf-text-group-delete-button a').live('click', function(e){
            $(this).parent().parent().remove();
        });
    });
    </script>
<mt:Loop name="text_group_loop">
    <mt:Var name="__counter__" setvar="text_group_counter">
    <mt:If name="__last__"><mt:Var name="last_text_group" value="1"></mt:If>
    <mt:If name="__first__">
        <div id="<mt:Var name="field_name">_multiusesinglelinetextgroupcf_container">
    </mt:If>
    <mt:Loop name="fields_loop">
        <mt:If name="__first__">
            <ul class="cf-text-group"<mt:If name="text_group_counter" gt="1"> style="border-top: 1px solid #ccc; padding-top: 4px;"</mt:If>>
        </mt:If>
                <mt:Var name="field_template">
        <mt:If name="__last__">
                <li class="cf-text-group-delete-button" style="text-align: right;">
                    <a href="javascript:void(0)" class="icon-left icon-error">
                        Delete this <mt:Var name="text_group_label"> field group
                    </a>
                </li>
            </ul>
        </mt:If>
    </mt:Loop>
    <mt:If name="__last__">
        </div>
        <p id="create-new-link">
            <a href="javascript:addGroup('<mt:Var name="field_name">_multiusesinglelinetextgroupcf_container','<mt:Var name="field_name">')" class="icon-left icon-create">
                Add another <mt:Var name="text_group_label"> field group
            </a>
        </p>
    </mt:If>
    <mt:If name="__last__">
        <mt:Loop name="fields_loop">
            <mt:If name="__first__">
                <ul class="cf-text-group" style="border-top: 1px solid #ccc; padding-top: 4px; display: none;" id="<mt:Var name="field_name">_multiusesinglelinetextgroupcf_invisible-field">
            </mt:If>
                    <mt:Var name="invisible_field_template">
            <mt:If name="__last__">
                    <li class="cf-text-group-delete-button" style="text-align: right;">
                        <a href="javascript:void(0)" class="icon-left icon-error">
                            Delete this <mt:Var name="text_group_label"> field group
                        </a>
                    </li>
                </ul>
            </mt:If>
        </mt:Loop>
    </mt:If>
</mt:Loop>
    };
}



sub _field_html_params {
    # The principle thing to do here is add the field value to the options
    # loop.
    my ($key, $tmpl_key, $tmpl_param) = @_;
    my $app = MT->instance;

    # Only proceed if there are values to process.med
    if ($tmpl_param->{field_value}) {
        # The field values are saved as YAML. Grab the values, convert them to a
        # string, and push them into the options loop.
        my $yaml = YAML::Tiny->new;
        $yaml = YAML::Tiny->read_string( $tmpl_param->{field_value} );

        # Step through the saved YAML to populate fields.
        my $option_loop = $tmpl_param->{option_loop};
        my @new_options;
        foreach my $field_name ( keys %{$yaml->[0]} ) {
            my $counter = 1;
            foreach my $option ( @$option_loop ) {
                my $label = $option->{label};
                push @new_options, { 
                    is_selected => $option->{is_selected},
                    label       => $label,
                    option      => $option->{option},
                    value       => $yaml->[0]->{ $field_name }->{ dirify($label) },
                };
                $counter++;
            }
        }
        $tmpl_param->{option_loop} = \@new_options;
    }
}

sub _multi_field_html_params {
    # The principle thing to do here is add the field value to the options
    # loop.
    my ($key, $tmpl_key, $tmpl_param) = @_;
    my $app = MT->instance;

    my @group_loop;
    # Step through the saved YAML to populate fields.
    my $option_loop = $tmpl_param->{option_loop};

    # Only proceed if there are values to process.
    if ($tmpl_param->{field_value}) {
        # The field values are saved as YAML. Grab the values, convert them to a
        # string, and push them into the options loop.
        my $yaml = YAML::Tiny->new;
        $yaml = YAML::Tiny->read_string( $tmpl_param->{field_value} );

        # The $field_name is the custom field basename.
        foreach my $field_name ( keys %{$yaml->[0]} ) {
            my $field = $yaml->[0]->{$field_name};
            undef @group_loop;
            # The $group_num is the group order/parent of the values. Sort
            # it so that they are displayed in the order they were saved.
            foreach my $group_num ( sort keys %{$field} ) {
                my @fields_loop;
                # Now push the saved field value into the option loop.
                foreach my $option ( @$option_loop ) {
                    my $label = $option->{label};
                    push @fields_loop, { 
                        is_selected => $option->{is_selected},
                        label       => $label,
                        option      => $option->{option},
                        value       => $field->{$group_num}->{dirify($label)},
                    };
                }
                push @group_loop, {
                    fields_loop => \@fields_loop,
                };
            }
        }
    }
    # Even if there was no saved data to recall, we want to provide a
    # starting point for the user to enter data. Populate that starting
    # point.
    if ( ! scalar @group_loop ) {
        my @fields_loop;
        foreach my $option ( @$option_loop ) {
            my $label = $option->{label};
            push @fields_loop, { 
                is_selected => $option->{is_selected},
                label       => $label,
                option      => $option->{option},
            };
        }
        push @group_loop, {
            fields_loop => \@fields_loop,
        };
    }

    $tmpl_param->{text_group_loop} = \@group_loop;

    # Get the basename of this customfield so that we can show the field's
    # display name next to the "add group" and "delete group" links.
    my $basename = $tmpl_param->{field_name};
    $basename =~ s/^customfield_(.*)$/$1/;
    my $field = MT->model('field')->load({
        blog_id => $app->blog->id,
        basename => $basename,
    });
    if ($field) {
        $tmpl_param->{text_group_label} = $field->name;
    }
}

1;

__END__
