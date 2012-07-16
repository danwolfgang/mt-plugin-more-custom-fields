package MoreCustomFields::SingleLineTextGroup;

use strict;

use MT 4.2;
use base qw(MT::Plugin);
use MT::Util qw( dirify );
use YAML::Tiny;

sub _options_field {
    return q{
<div class="textarea-wrapper">
    <textarea name="options"
        id="options"
        class="text full-width"><mt:Var name="options" escape="html"></textarea>
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
        <li>
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
    <li>
        <input type="hidden"
            name="<mt:Var name="field_name">_multiusesinglelinetextgroupcf_<mt:Var name="option" dirify="1">_cb_beacon"
            value="1" />
        <label for="<mt:var name="field_name">_multiusesinglelinetextgroupcf_<mt:Var name="option" dirify="1">">
            <mt:Var name="option">
        </label>
        <div class="textarea-wrapper">
            <input type="text"
                name="<mt:var name="field_name">_multiusesinglelinetextgroupcf_<mt:Var name="option" dirify="1">_invisible"
                id="<mt:var name="field_name">_multiusesinglelinetextgroupcf_<mt:Var name="option" dirify="1">"
                value=""
                class="full-width ti" />
        </div>
    </li>
</mt:SetVarTemplate>
<mt:SetVarTemplate name="field_template">
    <li>
        <input type="hidden"
            name="<mt:Var name="field_name">_multiusesinglelinetextgroupcf_<mt:Var name="option" dirify="1">_cb_beacon"
            value="1" />
        <label for="<mt:var name="field_name">_multiusesinglelinetextgroupcf_<mt:Var name="option" dirify="1">">
            <mt:Var name="option">
        </label>
        <div class="textarea-wrapper">
            <input type="text"
                name="<mt:var name="field_name">_multiusesinglelinetextgroupcf_<mt:Var name="option" dirify="1">"
                id="<mt:var name="field_name">_multiusesinglelinetextgroupcf_<mt:Var name="option" dirify="1">"
                value="<mt:Var name="value" escape="html">"
                class="full-width ti" />
        </div>
    </li>
</mt:SetVarTemplate>

<mt:Loop name="text_group_loop">
    <mt:Var name="__counter__" setvar="text_group_counter">
    <mt:If name="__first__">
        <div class="multiusesinglelinetextgroupcf_container mt<mt:Version sprintf="%d">"
            id="<mt:Var name="field_name">_multiusesinglelinetextgroupcf_container">
    </mt:If>
    <mt:Loop name="fields_loop">
        <mt:If name="__first__">
            <ul class="cf-text-group">
        </mt:If>
                <mt:Var name="field_template">
        <mt:If name="__last__">
                <li class="cf-text-group-delete-button">
                    <a href="javascript:void(0)"
                        onclick="jQuery(this).parent().parent().remove()"
                        class="icon-left icon-error">
                        Delete this <mt:Var name="text_group_label"> field group
                    </a>
                </li>
            </ul>
        </mt:If>
    </mt:Loop>
    <mt:If name="__last__">
        </div>
        <p id="create-new-link">
            <a href="javascript:addSingleLineTextGroup('<mt:Var name="field_name">_multiusesinglelinetextgroupcf_container','<mt:Var name="field_name">')"
                class="icon-left icon-create">
                Add another <mt:Var name="text_group_label"> field group
            </a>
        </p>
    </mt:If>
    <!-- This is to create the "hidden" group, used for the "add another" link. -->
    <mt:If name="__last__">
        <mt:Loop name="fields_loop">
            <mt:If name="__first__">
                <ul class="cf-text-group"
                    id="<mt:Var name="field_name">_multiusesinglelinetextgroupcf_invisible-field"
                    style="display: none;">
            </mt:If>
                    <mt:Var name="invisible_field_template">
            <mt:If name="__last__">
                    <li class="cf-text-group-delete-button">
                        <a href="javascript:void(0)"
                            onclick="jQuery(this).parent().parent().remove()"
                            class="icon-left icon-error">
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

    # Only proceed if there are values to process.
    if ($tmpl_param->{field_value}) {
        # The field values are saved as YAML. Grab the values, convert them to
        # a string, and push them into the options loop.
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
            push @fields_loop, { 
                is_selected => $option->{is_selected},
                label       => $option->{label},
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
        #Don't grab the blog_id because that keeps system-wide setting from working ok...
        #blog_id => $app->blog->id || '0',
        basename => $basename,
    });
    if ($field) {
        $tmpl_param->{text_group_label} = $field->name;
    }
}

# This is called by MoreCustomFields::Plugin::post_save, which is the 
# post-save callback handler. Save the data for this custom field type.
sub _save {
    my ($arg_ref) = shift;
    my $app             = $arg_ref->{app};
    my $obj             = $arg_ref->{object};
    my $user_field_name = $arg_ref->{user_field_name};

    # Now look at the individual text field in the group to determine if 
    # it's checked.
    if( $app->param( /^customfield_(.*?)_multiusesinglelinetextgroupcf_$user_field_name$/ ) ) { 
        my $field_basename = $1;
        my $field_name = "customfield_$1_multiusesinglelinetextgroupcf_$user_field_name";

        # Use a group number to hold each group of text boxes together.
        my $group_num = 1;
        # Save the values to an array
        my @field_data = $app->param($field_name);
        # ...and note the size of the array. We use this to see if the last 
        # text group might be empty
        my $last_group = scalar @field_data;

        # If $last_group is 0, then it means there is no data to save. The 
        # user is probably trying to delete all data, so we need to "write"
        # nothing so that the customfield erases any previously-saved data.
        if ($last_group == 0) {
            $app->param("customfield_$1", '');
        }

        foreach my $field_value ( @field_data ) {
            # Is this the last text group?
            if ( $last_group == $group_num ) {
                # This is the last text group. Is there a value saved, or is
                # it just an emtpy field? If empty, just give up.
                if ($field_value eq '') {
                    next;
                }
            }

            # Store this field's data as YAML.
            my $yaml = YAML::Tiny->new;

            # If any options for this CF have already been read and set,
            # grab them so we can just continue appending to them.
            if ( $app->param("customfield_$1") ) {
                $yaml = YAML::Tiny->read_string( $app->param("customfield_$1") );
            }

            # Write the YAML.
            $yaml->[0]->{$1}->{$group_num}->{$user_field_name} = $field_value;
            # Turn that YAML into a plain old string.
            my $result = $yaml->write_string();

            # Save the new result to the *real* field name, which
            # should be written to the DB.
            $app->param("customfield_$1", $result);

            # Increment the group number so that the next text group 
            # gets its own YAML key.
            $group_num++;
        }

        # Destory the specially-assembled fields, because they make MT barf.
        $app->delete_param($field_name);
        $app->delete_param($field_name.'_cb_beacon');
        $app->delete_param($field_name.'_invisible')
    }
}

# This is called by MoreCustomFields::Plugin::_load_tags. Create the tags 
# associated with this custom field type.
sub _create_tags {
    my ($arg_ref) = @_;
    my $tags = $arg_ref->{tags};

    # Grab the field definitions, then use those definitions to load the
    # appropriate objects. Finally, turn those into a block tag.
    my @field_defs = MT->model('field')->load({
        type => 'multi_use_single_line_text_group',
    });
    foreach my $field_def (@field_defs) {
        my $tag = $field_def->tag;
        # Load the objects (entry, author, whatever) based on the current
        # field definition.
        my $obj_type = $field_def->obj_type;
        my $basename = 'field.' . $field_def->basename;
        # Create the actual tag Use the tag name and append "Loop" to it.
        $tags->{block}->{$tag . 'Loop'} = sub {
            my ( $ctx, $args, $cond ) = @_;
            # Use the $obj_type to figure out what context we're in.
            my $obj = $ctx->stash($obj_type);
            # Then load the saved YAML
            my $yaml = YAML::Tiny->read_string( $obj->$basename );
            # The $field_name is the custom field basename.
            foreach my $field_name ( keys %{$yaml->[0]} ) {
                my $field = $yaml->[0]->{$field_name};
                # Build the output tag content
                my $out = '';
                my $vars = $ctx->{__stash}{vars};
                my $count = 0;
                # The $group_num is the group order/parent of the values.
                # Sort it so that they are displayed in the order they
                # were saved.
                foreach my $group_num ( sort keys %{$field} ) {
                    local $vars->{'__first__'} = ($count++ == 0);
                    local $vars->{'__last__'} = ($count == scalar keys %{$field});
                    # Add the keys and values to the output
                    foreach my $value ( keys %{$field->{$group_num}} ) {
                        $vars->{$value} = $field->{$group_num}->{$value};
                    }
                    defined( $out .= $ctx->slurp( $args, $cond ) ) or return;
                }
                return $out;
            }
        };
    }

    return $tags;
}

1;

__END__
