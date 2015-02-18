package MoreCustomFields::SelectedAssets;

use strict;

use MT 4.2;
use base qw(MT::Plugin);

sub _field_html {
    return q{
<input name="<mt:Var name="field_name">"
    id="<mt:Var name="field_id">"
    class="full-width selected-objects hidden"
    type="hidden"
    value="<mt:Var name="field_value">" />
<input name="<mt:Var name="field_name">_cb_beacon"
    id="<mt:Var name="field_id">"
    class="hidden"
    type="hidden"
    value="1" />

<a
<mt:If tag="Version" lt="5">
    onclick="return openDialog(this.form, 'list_assets', 'blog_id=<mt:Var name="blog_id">&amp;edit_field=<mt:Var name="field_id">&amp;selected_assets_cf=1&amp;_type=asset&amp;dialog_view=1&amp;asset_select=1<mt:If name="asset_type" ne="asset">&amp;filter=class&amp;filter_val=<mt:Var name="asset_type">&amp;require_type=<mt:Var name="asset_type"></mt:If>')"
<mt:Else>
    onclick="jQuery.fn.mtDialog.open('<mt:Var name="script_uri">?__mode=dialog_list_asset&amp;edit_field=<mt:Var name="field_id">&amp;blog_id=<mt:Var name="blog_id">&amp;no_insert=1&amp;selected_assets_cf=1<mt:If name="asset_type" ne="asset">&amp;filter=class&amp;filter_type=<mt:Var name="asset_type"></mt:If>')"
</mt:If>
    class="<mt:If tag="Version" lt="5">mt4-choose </mt:If>button">
    Choose asset
</a>

<ul class="custom-field-selected-objects mcf-listing"
    id="custom-field-selected-objects_<mt:Var name="field_name">">
<mt:Loop name="selected_objects_loop">
    <li id="obj-<mt:Var name="obj_id">" class="sortable">
        <span class="obj-title"><mt:Var name="obj_title"></span>
        <a href="<mt:Var name="script_uri">?__mode=view&amp;_type=<mt:Var name="obj_class">&amp;id=<mt:Var name="obj_id">&amp;blog_id=<mt:Var name="obj_blog_id">"
            class="edit"
            target="_blank"
            title="Edit in a new window."><img 
                src="<mt:Var name="static_uri">images/status_icons/draft.gif"
                width="9" height="9" alt="Edit" /></a>
        <a href="<mt:Var name="obj_permalink">"
            class="view"
            target="_blank"
            title="View in a new window."><img
                src="<mt:Var name="static_uri">images/status_icons/view.gif"
                width="13" height="9" alt="View" /></a>
        <img class="remove"
            alt="Remove selected asset"
            title="Remove selected asset"
            src="<mt:Var name="static_uri">images/status_icons/close.gif"
            width="9" height="9" />
    </li>
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

    my $field_name  = $tmpl_param->{field_name};

    # Several dropdowns may be needed, because several entries were selected.
    my $field_value = $tmpl_param->{field_value};
    my @asset_ids = split(/,\s?/, $field_value);

    my @obj_ids_loop;
    foreach my $asset_id (@asset_ids) {
        # Verify that $assetid is a number. If no Selected Assets are found, 
        # it's possible $assetid could be just a space character, which throws
        # an error. So, this check ensures we always have a valid asset ID.
        next unless $asset_id =~ m/\d+/;

        my $asset = MT->model('asset')->load($asset_id)
            or next;

        push @obj_ids_loop, {
            field_basename => $field_name,
            obj_id         => $asset_id,
            obj_title      => $asset->label,
            obj_class      => 'asset',         # For the edit link.
            obj_blog_id    => $asset->blog_id,
            obj_permalink  => $asset->url,     # For the view link.
        };
    }
    $tmpl_param->{selected_objects_loop} = \@obj_ids_loop;
}

# The SelectedAssets tag will let you intelligently output the links you selected. Use:
# <mt:SelectedAssets basename="selected_assets">
#   <mt:If name="__first__">
#     <ul>
#   </mt:If>
#     <li><a href="<mt:AssetURL>"><mt:AssetLabel></a></li>
#   <mt:If name="__last__">
#     </ul>
#   </mt:If>
# </mt:SelectedAssets>
sub tag_selected_assets {
    my ($ctx, $args, $cond) = @_;
    my $builder = $ctx->stash('builder');
    my $tokens  = $ctx->stash('tokens');
    my $res     = '';

    # The basename of the custom field you want to grab must be specified.
    # It's used later, to load the field data.
    my $cf_basename = $args->{basename};
    if (!$cf_basename) {
        return $ctx->error( 'The SelectedAssets block tag requires the '
            . 'basename argument. The basename should be the Selected '
            . 'Assets Custom Fields field basename.' );
    }

    # Grab the field name with the collected data from above. The basename 
    # must be unique so it's a good thing to key off of!
    my $field = CustomFields::Field->load( { basename => $cf_basename, } );
    return $ctx->error('A Selected Assets Custom Field with this basename '
        . 'could not be found.') if !$field;

    my $basename = 'field.'.$field->basename;

    # Use Custom Fields find_stashed_by_type to load the correct object. This
    # will decide if it's an entry, page, category, folder, or author archive,
    # then load the object and return it to us.
    use CustomFields::Template::ContextHandlers;
    my $object = eval {
        CustomFields::Template::ContextHandlers::find_stashed_by_type(
            $ctx, $field->obj_type
        )
    };
    return $ctx->error($@) if $@;

    # Create an array of the asset IDs held in the field.
    # $object->$basename is the lookup that actually grabs the data.
    my @assetids = split(/,\s?/, $object->$basename)
      if ($object && $object->$basename);
    my $i = 0;
    my $vars = $ctx->{__stash}{vars} ||= {};
    foreach my $assetid (@assetids) {
        # Verify that $assetid is a number. If no Selected Assets are found, 
        # it's possible $assetid could be just a space character, which throws
        # an error. So, this check ensures we always have a valid asset ID.
        if ($assetid =~ m/\d+/) {
            # Assign the meta vars
            local $vars->{__first__} = !$i;
            local $vars->{__last__} = !defined $assetids[$i + 1];
            local $vars->{__odd__} = ($i % 2) == 0; # 0-based $i
            local $vars->{__even__} = ($i % 2) == 1;
            local $vars->{__counter__} = $i + 1;
            # Assign the selected asset
            my $asset = MT::Asset->load( { id => $assetid, } );
            local $ctx->{__stash}{asset} = $asset;

            my $out = $builder->build($ctx, $tokens);
            if (!defined $out) {
                # A error--perhaps a tag used out of context. Report it.
                return $ctx->error( $builder->errstr );
            }
            $res .= $out;
            $i++; # Increment for the meta vars.
        }
    }
    return $res;
}

# The normal asset insert dialog works to insert into the entry Body field,
# but we want to override this to insert into the Selected Assets custom
# field, and use the insertSelectedAsset javascript.
sub asset_insert_param {
    my ($cb, $app, $param, $tmpl) = @_;
    my $plugin = $cb->plugin;

    my $field_basename = $param->{edit_field};
    $field_basename =~ s/^customfield_//; # Strip `customfield_` to get at the field basename.

    # Give up if this isn't a Selected Asset being inserted by trying to load
    # a custom field with the basename specified. (Because the asset inserter
    # is being overridden we're affecting a widely-used screen.)
    return 1 unless $field_basename
        && MT->model('field')->load({
            blog_id  => $param->{blog_id},
            basename => $field_basename,
            type => { like => 'selected_%' }, # Could be a `selected_[anything]`
        });

    my $ctx = $tmpl->context;
    my $asset = $ctx->stash('asset');

    my $html;
    # If this asset has a URL and file path then link it for easy previewing.
    if ($asset->url && $asset->file_path) {
        $html = '<a href="<mt:AssetURL>" target="_blank"><mt:AssetLabel encode_js="1"></a>';
    }
    else {
        $html = '<mt:AssetLabel encode_js="1">';
    }

    $param->{obj_title}     = $asset->label;
    $param->{obj_id}        = $asset->id;
    $param->{obj_class}     = 'asset'; # For the edit link.
    $param->{obj_permalink} = $asset->url || '';
    $param->{obj_blog_id}   = $app->blog->id;

    my $new_tmpl = $plugin->load_tmpl('insert_object.mtml', $param);

    # Use the new template.
    $tmpl->text($new_tmpl->text());
}

1;

__END__
