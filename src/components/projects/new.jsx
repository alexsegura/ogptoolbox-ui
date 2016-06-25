// OGPToolbox-Editor -- Web editor for OGP toolbox
// By: Emmanuel Raviart <emmanuel.raviart@data.gouv.fr>
//
// Copyright (C) 2016 Etalab
// https://git.framasoft.org/etalab/ogptoolbox-editor
//
// OGPToolbox-Editor is free software you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// OGPToolbox-Editor is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.


import {Component, PropTypes} from "react"
import {connect} from "react-redux"
import Form from "react-jsonschema-form"

import {createProject} from "../../actions"
import {schema, uiSchema} from "../../schemas/project"


class ProjectNew extends Component {
  static breadcrumbName = "New Project"
  static propTypes = {
    authentication: PropTypes.object.isRequired,
    createProject: PropTypes.func.isRequired,
  }
  onSubmit(form) {
    const {authentication, createProject} = this.props
    createProject(authentication, form.formData)
  }
  render() {
    return (
      <Form
        onSubmit={this.onSubmit.bind(this)}
        schema={schema}
        uiSchema={uiSchema}
      />
    )
  }
}

export default connect(
  state => ({authentication: state.authentication}),
  {
    createProject,
  },
)(ProjectNew)
