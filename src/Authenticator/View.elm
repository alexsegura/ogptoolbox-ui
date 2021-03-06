module Authenticator.View exposing (..)

import Authenticator.Model exposing (Model, Route(..))
import Authenticator.ResetPassword as ResetPassword
import Authenticator.SignIn as SignIn
import Authenticator.SignOut as SignOut
import Authenticator.SignUp as SignUp
import Authenticator.Update exposing (Msg(..))
import Html exposing (Html)
import Html.App
import I18n


modalTitle : Route -> String
modalTitle route =
    case route of
        ResetPasswordRoute ->
            "Password lost?"

        SignInRoute ->
            "Sign in to contribute"

        SignOutRoute ->
            "Sign out and contribute later"

        SignUpRoute ->
            "Create your account"


viewModalBody : I18n.Language -> Route -> Model -> Html Msg
viewModalBody language route model =
    case route of
        ResetPasswordRoute ->
            Html.App.map ResetPasswordMsg (ResetPassword.viewModalBody model.resetPassword)

        SignInRoute ->
            Html.App.map SignInMsg (SignIn.viewModalBody language model.signIn)

        SignOutRoute ->
            Html.App.map SignOutMsg (SignOut.viewModalBody model.signOut)

        SignUpRoute ->
            Html.App.map SignUpMsg (SignUp.viewModalBody model.signUp)
