package MoreCustomFields::SelectedAssets;

use strict;

use MT 4.2;
use base qw(MT::Plugin);
use CustomFields::Util qw( get_meta save_meta field_loop _get_html );
use MT::Util
  qw( relative_date offset_time offset_time_list epoch2ts ts2epoch format_ts encode_html dirify );

sub _field_html {
    return q{
<script type="text/javascript">
    function insertSelectedAsset(asset_label, asset_id, el_id) {
        var sa = document.getElementById(el_id);
        sa.setAttribute('value', asset_id);

        var sa_preview_id = el_id + '_preview';
        document.getElementById(sa_preview_id).innerHTML = asset_label;
    }
</script>

<ul class="custom-field-selected-assets" id="custom-field-selected-assets_<mt:Var name="field_name">" style="margin-top: 3px;">
<mt:Loop name="selectedassets_loop">
    <li style="padding-bottom: 3px;" id="li_<mt:Var name="field_name">_selectedassetcf_<mt:Var name="__counter__">">
        <mt:SetVarBlock name="selectedasset"><mt:Var name="field_selected"></mt:SetVarBlock>
        <input name="<mt:Var name="field_name">_selectedassetscf_<mt:Var name="__counter__">" id="<mt:Var name="field_name">_selectedassetscf_<mt:Var name="__counter__">" class="hidden" type="hidden" value="<mt:Var name="field_selected">" />
        <button
            style="background: #333 url('<mt:StaticWebPath>images/buttons/button.gif') no-repeat 0 center; border:none; border-top:1px solid #d4d4d4; font-weight: bold; font-size: 14px; line-height: 1.3; text-decoration: none; color: #eee; cursor: pointer; padding: 2px 10px 4px;"
            type="submit"
            onclick="return openDialog(this.form, 'list_assets', 'blog_id=<mt:Var name="blog_id">&amp;edit_field=<mt:Var name="field_name">_selectedassetscf_<mt:Var name="__counter__">&amp;_type=asset&amp;dialog_view=1&amp;asset_select=1<mt:if name="asset_type" ne="asset">&amp;filter=class&amp;filter_val=<mt:var name="asset_type">&amp;require_type=<mt:var name="asset_type"></mt:if>')">
            Choose <mt:Var name="asset_type_label" capitalize="1">
        </button>
        <span id="<mt:Var name="field_name">_selectedassetscf_<mt:Var name="__counter__">_preview" class="preview" style="padding-left: 8px;">
            <mt:Asset id="$selectedasset">
                <mt:If tag="AssetType" like="(file|image|audio|video)">
                    <a href="<mt:AssetURL>" target="_blank"><mt:AssetLabel></a>
                <mt:Else>
                    <mt:AssetLabel>
                </mt:If>
            </mt:Asset>
        </span>
        <a style="padding: 3px 5px;" href="javascript:removeSelectedAsset('li_<mt:Var name="field_name">_selectedassetcf_<mt:Var name="__counter__">');" title="Remove selected <mt:Var name="asset_type_label">"><img src="<mt:StaticWebPath>images/status_icons/close.gif" width="9" height="9" alt="Remove selected <mt:Var name="asset_type_label">" /></a>
    </li>
</mt:Loop>
</ul>
<p><a class="add-category-new-parent-link" href="javascript:addSelectedAsset('<mt:Var name="field_name">', '<mt:Var name="blog_id">', '<mt:Var name="asset_type_label" capitalize="1">', '<mt:if name="asset_type" ne="asset">&amp;filter=class&amp;filter_val=<mt:var name="asset_type">&amp;require_type=<mt:var name="asset_type"></mt:if>');">Add an <mt:Var name="asset_type_label"></a></p>

    <input id="sa-new-input-<mt:Var name="field_name">" style="display: none;" class="hidden" type="hidden" />
    <button
        style="display: none;"
        id="sa-new-button-<mt:Var name="field_name">"
        type="submit">
        Choose Asset
    </button>
    <span id="sa-new-preview-<mt:Var name="field_name">" class="preview" style="display: none;">
    </span>


<input type="hidden" id="sa-adder-<mt:Var name="field_name">" value="1" />

<script type="text/javascript">
    function addSelectedAsset(cf_name, blog_ids, label, filter) {
        // Update the counter, so that each addition gets a unique number
        var adder_el = 'sa-adder-' + cf_name;
        var numi = document.getElementById(adder_el);
        var num = (document.getElementById(adder_el).value -1) + 2;
        numi.value = num;

        // Create the new input field.
        var newInputName = cf_name + '_selectedassetscf_new' + num;
        var new_el = 'sa-new-input-' + cf_name;
        var newInput = document.getElementById(new_el).cloneNode(true);
        newInput.setAttribute('name', newInputName);
        newInput.setAttribute('id',   newInputName);

        // Create the new button
        var new_el = 'sa-new-button-' + cf_name;
        var newButton = document.getElementById(new_el).cloneNode(true);
        newButton.removeAttribute('id');
        newButton.setAttribute('style', "background: #333 url('<mt:StaticWebPath>images/buttons/button.gif') no-repeat 0 center; border:none; border-top:1px solid #d4d4d4; font-weight: bold; font-size: 14px; line-height: 1.3; text-decoration: none; color: #eee; cursor: pointer; padding: 2px 10px 4px;");
        var onclick = "return openDialog(this.form, 'list_assets', 'blog_id=<mt:Var name="blog_id">&amp;edit_field=" + newInputName + "&amp;_type=asset&amp;dialog_view=1&amp;asset_select=1" + filter + "')";
        
        newButton.setAttribute('onclick', onclick);
        newButton.innerHTML = 'Choose ' + label;

        // Create the preview area
        var newPreviewName = cf_name + '_selectedassetscf_new' + num + '_preview';
        var new_el = 'sa-new-preview-' + cf_name;
        var newPreview = document.getElementById(new_el).cloneNode(true);
        newPreview.setAttribute('id', newPreviewName);
        newPreview.setAttribute('style', 'padding: 0 3px 0 8px;');

        // Add the "delete" icon
        var newDeleteIcon = document.createElement('img');
        newDeleteIcon.setAttribute('src', '<mt:StaticWebPath>images/status_icons/close.gif');
        newDeleteIcon.setAttribute('width', '9');
        newDeleteIcon.setAttribute('height', '9');
        newDeleteIcon.setAttribute('alt', 'Remove selected asset');

        //Add the "delete" link
        var newDeleteLink = document.createElement('a');
        newDeleteLink.setAttribute('style', "margin-left: 5px;");
        newDeleteLink.setAttribute('style', 'padding: 3px 5px;');
        var href = "javascript:removeSelectedAsset('li_" + newInputName + "');";
        newDeleteLink.setAttribute('href', href);
        newDeleteLink.setAttribute('title', 'Remove selected asset');
        newDeleteLink.appendChild(newDeleteIcon);

        // Create a new list item and add the new select drop-down to it.
        var newListItem = document.createElement('li');
        newListItem.setAttribute('id', 'li_' + newInputName);
        newListItem.appendChild(newInput);
        newListItem.appendChild(newButton);
        newListItem.appendChild(newPreview);
        newListItem.appendChild(newDeleteLink);

        // Place the new list item in the drop-down selectors list.
        var CF = document.getElementById('custom-field-selected-assets_' + cf_name);
        CF.appendChild(newListItem);
        
        // After the user clicks to Add an Asset, they are going to want to
        // click Choose Asset. We might as well save them the effort.
        openDialog(this.form, 'list_assets', 'blog_id=<mt:Var name="blog_id">&amp;edit_field=' + newInputName + '&amp;_type=asset&amp;&amp;dialog_view=1&amp;asset_select=1' + filter );
    }

    function removeSelectedAsset(l) {
        var listItem = document.getElementById(l);
        listItem.parentNode.removeChild(listItem);
    }
</script>
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
    my @assetids = split(/,\s?/, $field_value);

    my @assetids_loop;
    foreach my $assetid (@assetids) {
        # Verify that $assetid is a number. If no Selected Assets are found, 
        # it's possible $assetid could be just a space character, which throws
        # an error. So, this check ensures we always have a valid asset ID.
        if ($assetid =~ m/\d+/) {
            push @assetids_loop, { field_basename => $field_name,
                                   field_selected => $assetid,
                                 };
        }
    }
    $tmpl_param->{selectedassets_loop} = \@assetids_loop;
}

sub tag_selected_assets {
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
    my $obj_type = $field->obj_type;
    
    # Grab the correct object, based on the object type from the custom field.
    my $object;
    if ( $obj_type == 'entry' ) {
        $object = MT::Entry->load( { id => $ctx->stash('entry')->id, } );
    }
    elsif ( $obj_type == 'page' ) {
        # Entries and Pages are both stored in the mt_entry table
        $object = MT::Entry->load( { id => $ctx->stash('page')->id, } );
    }
    elsif ( $obj_type == 'category' ) {
        $object = MT::Category->load( { id => $ctx->stash('category')->id, } );
    }
    elsif ( $obj_type == 'folder' ) {
        # Categories and Folders are both stored in the mt_category table
        $object = MT::Category->load( { id => $ctx->stash('category')->id, } );
    }
    elsif ( $obj_type == 'author' ) {
        $object = MT::Author->load( { id => $ctx->stash('author')->id, } );
    }
    
    # Create an array of the asset IDs held in the field.
    # $object->$basename is the lookup that actually grabs the data.
    my @assetids = split(/,\s?/, $object->$basename);
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

sub asset_insert_param {
    # The normal asset insert dialog works to insert into the entry Body 
    # field, but we want to override this to insert into the Selected Assets
    # custom field, and use the insertSelectedAsset javascript.
    my ($cb, $app, $param, $tmpl) = @_;
    my $plugin = $cb->plugin;

    # Give up if this isn't a Selected Asset being inserted.
    return 1 unless $app->param('edit_field') =~ /selectedassetscf/;

    my $ctx = $tmpl->context;
    my $asset = $ctx->stash('asset');
    
    my $html;
    # If this is a file, image, audio, or video asset, the asset can be
    # linked to a real file, for easy previewing.
    if ($asset->class_type =~ /file|image|audio|video/) {
        $html = '<a href="<mt:AssetURL>" target="_blank"><mt:AssetLabel encode_js="1"></a>';
    }
    else {
        $html = '<mt:AssetLabel encode_js="1">';
    }

    # Craft an entirely new inserter template. The only thing we want to do
    # is add the asset to the Selected Asset CF. No need to work with other
    # custom fields, the Entry Asset Manager, or insert into the entry Body.
    my $new_tmpl = <<TMPL;
<mt:include name="dialog/header.tmpl">
<script type="text/javascript">
    window.parent.insertSelectedAsset('$html', '<mt:AssetID>', '<mt:var name="edit_field" escape="js">');
    closeDialog();
</script>
<div class="actions-bar-inner pkg actions">
    <form action="" method="get" onsubmit="return false">
        <button
            onclick="closeDialog(); return false"
            type="submit"
            accesskey="x"
            class="cancel"
            title="<__trans phrase="Close (x)">"
            ><__trans phrase="Close"></button>
    </form>
</div>
<mt:include name="dialog/footer.tmpl">
TMPL

    # Use the new template.
    $tmpl->text($new_tmpl);
}

1;

__END__
