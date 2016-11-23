module Main exposing (..)

import About
import Authenticator.Model
import Authenticator.Update
import Authenticator.View
import Dom.Scroll
import Examples.State
import Examples.Types
import Examples.View
import Help
import Home
import Hop.Types exposing (Location)
import Html exposing (..)
import Html.App
import Html.Attributes exposing (..)
import Html.Attributes.Aria exposing (ariaHidden, ariaLabelledby)
import Html.Events exposing (onInput, onSubmit, onWithOptions)
import Html.Helpers exposing (aForPath)
import Json.Decode
import Navigation
import Organizations
import Routes
    exposing
        ( addSearchQueryToLocation
        , ExamplesNestedRoute(..)
        , getSearchQuery
        , makeUrl
        , makeUrlFromLocation
        , OrganizationsNestedRoute(..)
        , Route(..)
        , ToolsNestedRoute(..)
        , urlParser
        )
import Task
import Tools
import Views exposing (viewNotFound)


main : Program Never
main =
    Navigation.program urlParser
        { init = init
        , update = update
        , urlUpdate = urlUpdate
        , view = view
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { aboutModel : About.Model
    , authenticationMaybe : Maybe Authenticator.Model.Authentication
    , authenticatorModel : Authenticator.Model.Model
    , authenticatorRouteMaybe : Maybe Authenticator.Model.Route
    , examplesModel : Examples.Types.Model
    , helpModel : Help.Model
    , homeModel : Home.Model
    , location : Hop.Types.Location
    , organizationsModel : Organizations.Model
    , route : Route
    , searchInputValue : String
    , toolsModel : Tools.Model
    }


init : ( Route, Hop.Types.Location ) -> ( Model, Cmd Msg )
init ( route, location ) =
    { aboutModel = About.init
    , authenticationMaybe = Nothing
    , authenticatorModel = Authenticator.Model.init
    , authenticatorRouteMaybe = Nothing
    , examplesModel = Examples.State.init
    , helpModel = Help.init
    , homeModel = Home.init
    , organizationsModel = Organizations.init
    , location = location
    , route = route
    , searchInputValue = ""
    , toolsModel = Tools.init
    }
        |> urlUpdate ( route, location )



-- ROUTING


urlUpdate : ( Route, Hop.Types.Location ) -> Model -> ( Model, Cmd Msg )
urlUpdate ( route, location ) model =
    let
        searchQuery =
            getSearchQuery location

        model' =
            { model
                | location = location
                , route = route
            }

        ( model'', cmd ) =
            case route of
                AboutRoute ->
                    ( model', Cmd.none )

                ExamplesRoute childRoute ->
                    let
                        ( examplesModel, childCmd ) =
                            Examples.State.urlUpdate ( childRoute, location ) model'.examplesModel
                    in
                        ( { model'
                            | examplesModel = examplesModel
                            , searchInputValue = searchQuery
                          }
                        , Cmd.map translateExamplesMsg childCmd
                        )

                HelpRoute ->
                    ( model', Cmd.none )

                HomeRoute ->
                    let
                        ( homeModel, childCmd ) =
                            Home.update (Home.Load searchQuery) model.authenticationMaybe model'.homeModel
                    in
                        ( { model'
                            | homeModel = homeModel
                            , searchInputValue = searchQuery
                          }
                        , Cmd.map translateHomeMsg childCmd
                        )

                NotFoundRoute ->
                    ( model', Cmd.none )

                OrganizationsRoute childRoute ->
                    let
                        ( organizationsModel, childCmd ) =
                            Organizations.urlUpdate ( childRoute, location ) model'.organizationsModel
                    in
                        ( { model'
                            | organizationsModel = organizationsModel
                            , searchInputValue = searchQuery
                          }
                        , Cmd.map translateOrganizationsMsg childCmd
                        )

                ToolsRoute childRoute ->
                    let
                        ( toolsModel, childCmd ) =
                            Tools.urlUpdate ( childRoute, location ) model'.toolsModel
                    in
                        ( { model'
                            | toolsModel = toolsModel
                            , searchInputValue = searchQuery
                          }
                        , Cmd.map translateToolsMsg childCmd
                        )
    in
        model''
            ! [ Task.perform
                    (\_ -> Debug.crash "Dom.Scroll.toTop \"html-element\"")
                    (always NoOp)
                    (Dom.Scroll.toTop "html-element")
              , cmd
              ]



-- UPDATE


type Msg
    = AboutMsg About.InternalMsg
    | AuthenticatorMsg Authenticator.Update.Msg
    | AuthenticatorRouteMsg (Maybe Authenticator.Model.Route)
    | ExamplesMsg Examples.Types.InternalMsg
    | HelpMsg Help.InternalMsg
    | HomeMsg Home.InternalMsg
    | Navigate String
    | NoOp
    | OrganizationsMsg Organizations.InternalMsg
    | Search
    | SearchInputChanged String
    | ToolsMsg Tools.InternalMsg


aboutMsgTranslation : About.MsgTranslation Msg
aboutMsgTranslation =
    { onInternalMsg = AboutMsg
    , onNavigate = Navigate
    }


examplesMsgTranslation : Examples.Types.MsgTranslation Msg
examplesMsgTranslation =
    { onInternalMsg = ExamplesMsg
    , onNavigate = Navigate
    }


helpMsgTranslation : Help.MsgTranslation Msg
helpMsgTranslation =
    { onInternalMsg = HelpMsg
    , onNavigate = Navigate
    }


homeMsgTranslation : Home.MsgTranslation Msg
homeMsgTranslation =
    { onInternalMsg = HomeMsg
    , onNavigate = Navigate
    }


organizationsMsgTranslation : Organizations.MsgTranslation Msg
organizationsMsgTranslation =
    { onInternalMsg = OrganizationsMsg
    , onNavigate = Navigate
    }


toolsMsgTranslation : Tools.MsgTranslation Msg
toolsMsgTranslation =
    { onInternalMsg = ToolsMsg
    , onNavigate = Navigate
    }


translateAboutMsg : About.MsgTranslator Msg
translateAboutMsg =
    About.translateMsg aboutMsgTranslation


translateExamplesMsg : Examples.Types.MsgTranslator Msg
translateExamplesMsg =
    Examples.State.translateMsg examplesMsgTranslation


translateHelpMsg : Help.MsgTranslator Msg
translateHelpMsg =
    Help.translateMsg helpMsgTranslation


translateHomeMsg : Home.MsgTranslator Msg
translateHomeMsg =
    Home.translateMsg homeMsgTranslation


translateOrganizationsMsg : Organizations.MsgTranslator Msg
translateOrganizationsMsg =
    Organizations.translateMsg organizationsMsgTranslation


translateToolsMsg : Tools.MsgTranslator Msg
translateToolsMsg =
    Tools.translateMsg toolsMsgTranslation


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AboutMsg childMsg ->
            let
                ( aboutModel, childCmd ) =
                    About.update childMsg model.authenticationMaybe model.aboutModel
            in
                ( { model | aboutModel = aboutModel }, Cmd.map translateAboutMsg childCmd )

        AuthenticatorMsg childMsg ->
            let
                ( authenticatorModel, childCmd ) =
                    Authenticator.Update.update childMsg model.authenticatorModel

                changed =
                    authenticatorModel.authenticationMaybe /= model.authenticationMaybe

                model' =
                    { model
                        | authenticationMaybe = authenticatorModel.authenticationMaybe
                        , authenticatorModel = authenticatorModel
                        , authenticatorRouteMaybe =
                            if changed then
                                Nothing
                            else
                                model.authenticatorRouteMaybe
                    }

                ( model'', effect'' ) =
                    if changed then
                        update (Navigate "/") model'
                    else
                        ( model', Cmd.none )
            in
                model'' ! [ Cmd.map AuthenticatorMsg childCmd, effect'' ]

        AuthenticatorRouteMsg authenticatorRouteMaybe ->
            ( { model | authenticatorRouteMaybe = authenticatorRouteMaybe }, Cmd.none )

        ExamplesMsg childMsg ->
            let
                ( examplesModel, childCmd ) =
                    Examples.State.update childMsg model.authenticationMaybe model.examplesModel
            in
                ( { model | examplesModel = examplesModel }, Cmd.map translateExamplesMsg childCmd )

        HelpMsg childMsg ->
            let
                ( helpModel, childCmd ) =
                    Help.update childMsg model.authenticationMaybe model.helpModel
            in
                ( { model | helpModel = helpModel }, Cmd.map translateHelpMsg childCmd )

        HomeMsg childMsg ->
            let
                ( homeModel, childCmd ) =
                    Home.update childMsg model.authenticationMaybe model.homeModel
            in
                ( { model | homeModel = homeModel }, Cmd.map translateHomeMsg childCmd )

        Navigate path ->
            let
                command =
                    makeUrl path
                        |> Navigation.newUrl
            in
                ( model, command )

        NoOp ->
            ( model, Cmd.none )

        OrganizationsMsg childMsg ->
            let
                ( organizationsModel, childCmd ) =
                    Organizations.update childMsg model.authenticationMaybe model.organizationsModel
            in
                ( { model | organizationsModel = organizationsModel }, Cmd.map translateOrganizationsMsg childCmd )

        Search ->
            let
                command =
                    makeUrl ("/tools?q=" ++ model.searchInputValue)
                        |> Navigation.newUrl
            in
                ( model, command )

        SearchInputChanged searchInputValue ->
            ( { model | searchInputValue = searchInputValue }, Cmd.none )

        ToolsMsg childMsg ->
            let
                ( toolsModel, childCmd ) =
                    Tools.update childMsg model.authenticationMaybe model.toolsModel
            in
                ( { model | toolsModel = toolsModel }, Cmd.map translateToolsMsg childCmd )



-- VIEW


view : Model -> Html Msg
view model =
    let
        standardLayout content =
            div []
                ([ viewHeader model "container" ]
                    ++ content
                    ++ [ viewFooter
                       , viewAuthenticatorModal model
                       , viewBackdrop model
                       ]
                )

        fullscreenLayout content =
            div [ class "main-container" ]
                ([ div [ class "fixed-header" ]
                    [ viewHeader model "container-fluid" ]
                 ]
                    ++ content
                    ++ [ div [ class "fixed-footer" ]
                            [ text "© 2016 Open Government Partnership" ]
                       , viewAuthenticatorModal model
                       , viewBackdrop model
                       ]
                )

        searchQuery =
            getSearchQuery model.location
    in
        case model.route of
            AboutRoute ->
                standardLayout [ Html.App.map translateAboutMsg (About.view model.authenticationMaybe model.aboutModel) ]

            ExamplesRoute childRoute ->
                Examples.View.root model.authenticationMaybe model.examplesModel searchQuery
                    |> List.map (Html.App.map translateExamplesMsg)
                    |> case childRoute of
                        ExampleRoute _ ->
                            standardLayout

                        ExamplesIndexRoute ->
                            fullscreenLayout

            HelpRoute ->
                standardLayout [ Html.App.map translateHelpMsg (Help.view model.authenticationMaybe model.helpModel) ]

            HomeRoute ->
                standardLayout
                    [ Html.App.map translateHomeMsg
                        (Home.view model.homeModel (getSearchQuery model.location))
                    ]

            NotFoundRoute ->
                standardLayout
                    [ div [ class "row section" ]
                        [ div [ class "container" ]
                            [ viewNotFound
                            ]
                        ]
                    ]

            OrganizationsRoute childRoute ->
                Organizations.view model.authenticationMaybe model.organizationsModel searchQuery
                    |> List.map (Html.App.map translateOrganizationsMsg)
                    |> case childRoute of
                        OrganizationRoute _ ->
                            standardLayout

                        OrganizationsIndexRoute ->
                            fullscreenLayout

            ToolsRoute childRoute ->
                Tools.view model.authenticationMaybe model.toolsModel searchQuery
                    |> List.map (Html.App.map translateToolsMsg)
                    |> case childRoute of
                        ToolRoute _ ->
                            standardLayout

                        ToolsIndexRoute ->
                            fullscreenLayout


viewAuthenticatorModal : Model -> Html Msg
viewAuthenticatorModal model =
    case model.authenticatorRouteMaybe of
        Just authenticatorRoute ->
            div
                [ ariaLabelledby "modal-title"
                , attribute "role" "dialog"
                , attribute "tabindex" "-1"
                , class "modal fade in"
                , style [ ( "display", "block" ) ]
                ]
                [ div [ class "modal-dialog", id "login-overlay" ]
                    [ div [ class "modal-content" ]
                        [ div [ class "modal-header" ]
                            [ button
                                [ attribute "data-dismiss" "modal"
                                , class "close"
                                , onWithOptions
                                    "click"
                                    { preventDefault = True, stopPropagation = False }
                                    (Json.Decode.succeed (AuthenticatorRouteMsg Nothing))
                                , type' "button"
                                ]
                                [ span [ ariaHidden True ]
                                    [ text "×" ]
                                , span [ class "sr-only" ]
                                    [ text "Close" ]
                                ]
                            , h4 [ class "modal-title", id "modal-title" ]
                                [ text (Authenticator.View.modalTitle authenticatorRoute) ]
                            ]
                        , Html.App.map
                            AuthenticatorMsg
                            (Authenticator.View.viewModalBody authenticatorRoute model.authenticatorModel)
                        ]
                    ]
                ]

        Nothing ->
            text ""


viewBackdrop : Model -> Html Msg
viewBackdrop model =
    div [ classList [ ( "modal-backdrop in", model.authenticatorRouteMaybe /= Nothing ) ] ]
        []


viewFooter : Html msg
viewFooter =
    footer []
        [ div [ class "row section footer" ]
            [ div [ class "container" ]
                [ div [ class "row" ]
                    [ div [ class "col-xs-12 col-md-6" ]
                        [ div [ class "row" ]
                            [ div [ class "col-xs-6" ]
                                [ img [ alt "OGP logo", class "footer-logo", src "/img/ogp-logo.png" ]
                                    []
                                ]
                            , div [ class "col-xs-6" ]
                                [ h4 []
                                    [ text "Language" ]
                                , div [ class "dropdown dropdown-language" ]
                                    [ button
                                        [ attribute "aria-expanded" "true"
                                        , attribute "aria-haspopup" "true"
                                        , class "btn btn-default dropdown-toggle"
                                        , attribute "data-toggle" "dropdown"
                                        , id "dropdownMenu1"
                                        , type' "button"
                                        ]
                                        [ text "English                  "
                                        , span [ class "caret" ]
                                            []
                                        ]
                                    , ul [ attribute "aria-labelledby" "dropdownMenu1", class "dropdown-menu" ]
                                        [ li []
                                            [ a [ href "#" ]
                                                [ text "Français" ]
                                            ]
                                        , li []
                                            [ a [ href "#" ]
                                                [ text "Espanol" ]
                                            ]
                                        ]
                                    ]
                                ]
                            ]
                        , p [ class "info-box" ]
                            [ text """
The Open Government Partnership is a multilateral initiative that aims to secure concrete commitments
from governments to promote transparency, empower citizens, fight corruption, and harness new technologies
to strengthen governance. In the spirit of multi-stakeholder collaboration, OGP is overseen by a Steering Committee
including representatives of governments and civil society organizations.
""" ]
                        ]
                    , div [ class "col-xs-6 col-md-3" ]
                        [ h4 []
                            [ text "About" ]
                        , ul [ class "footer-menu" ]
                            [ li []
                                [ a [ href "#" ]
                                    [ text "Eligibility Criteria" ]
                                ]
                            , li []
                                [ a [ href "#" ]
                                    [ text "Develop a National Action Plan" ]
                                ]
                            , li []
                                [ a [ href "#" ]
                                    [ text "Self-Assessment Process" ]
                                ]
                            , li []
                                [ a [ href "#" ]
                                    [ text "Response Policy" ]
                                ]
                            , li []
                                [ a [ href "#" ]
                                    [ text "Civil Society Engagement" ]
                                ]
                            , li []
                                [ a [ href "#" ]
                                    [ text "Calendars and Deadlines" ]
                                ]
                            ]
                        ]
                    , div [ class "col-xs-6 col-md-3" ]
                        [ h4 []
                            [ text "How it works" ]
                        , ul [ class "footer-menu" ]
                            [ li []
                                [ a [ href "#" ]
                                    [ text "Home" ]
                                ]
                            , li []
                                [ a [ href "#" ]
                                    [ text "Profile" ]
                                ]
                            , li []
                                [ a [ href "#" ]
                                    [ text "Messages" ]
                                ]
                            ]
                        ]
                    ]
                , div [ class "row copyright" ]
                    [ div [ class "col-md-12" ]
                        [ text "© 2016 Open Government Partnership" ]
                    ]
                ]
            ]
        ]


viewHeader : Model -> String -> Html Msg
viewHeader model containerClass =
    let
        profileNavItem =
            case model.authenticationMaybe of
                Just authentication ->
                    li [] [ aForPath Navigate "/profile" [] [ text authentication.name ] ]

                Nothing ->
                    text ""

        signInOrOutNavItem =
            case model.authenticationMaybe of
                Just authentication ->
                    li []
                        [ a
                            [ href "#"
                            , onWithOptions
                                "click"
                                { preventDefault = True, stopPropagation = False }
                                (Json.Decode.succeed (AuthenticatorRouteMsg (Just Authenticator.Model.SignOutRoute)))
                            ]
                            [ text "Sign Out" ]
                        ]

                Nothing ->
                    li []
                        [ a
                            [ href "#"
                            , onWithOptions
                                "click"
                                { preventDefault = True, stopPropagation = False }
                                (Json.Decode.succeed (AuthenticatorRouteMsg (Just Authenticator.Model.SignInRoute)))
                            ]
                            [ text "Sign In" ]
                        ]

        signUpNavItem =
            case model.authenticationMaybe of
                Just authentication ->
                    text ""

                Nothing ->
                    li []
                        [ a
                            [ href "#"
                            , onWithOptions
                                "click"
                                { preventDefault = True, stopPropagation = False }
                                (Json.Decode.succeed (AuthenticatorRouteMsg (Just Authenticator.Model.SignUpRoute)))
                            ]
                            [ text "Sign Up" ]
                        ]
    in
        header []
            [ nav [ class "navbar navbar-default navbar-fixed-top", attribute "role" "navigation" ]
                [ div [ class containerClass ]
                    [ div [ class "navbar-header" ]
                        [ button
                            [ attribute "aria-controls" "navbar"
                            , attribute "aria-expanded" "false"
                            , class "navbar-toggle collapsed"
                            , attribute "data-target" "#navbar"
                            , attribute "data-toggle" "collapse"
                            , type' "button"
                            ]
                            [ span [ class "sr-only" ]
                                [ text "Toggle navigation" ]
                            , span [ class "icon-bar" ]
                                []
                            , span [ class "icon-bar" ]
                                []
                            , span [ class "icon-bar" ]
                                []
                            ]
                        , aForPath Navigate "/" [ class "navbar-brand" ] [ text "OGPtoolbox" ]
                        , p [ class "navbar-text" ]
                            [ text "tools and use cases for open government" ]
                        ]
                    , ul [ class "nav navbar-nav navbar-right" ]
                        [ profileNavItem
                        , signInOrOutNavItem
                        , signUpNavItem
                        , button [ class "btn btn-default btn-action", type' "button" ]
                            [ text "Add new" ]
                        ]
                    ]
                ]
            , nav [ class "navbar navbar-inverse" ]
                [ div [ class containerClass ]
                    [ div [ class "navbar-header" ]
                        [ button
                            [ attribute "aria-expanded" "false"
                            , class "navbar-toggle collapsed"
                            , attribute "data-target" "#bs-example-navbar-collapse-1"
                            , attribute "data-toggle" "collapse"
                            , type' "button"
                            ]
                            [ span [ class "sr-only" ]
                                [ text "Toggle navigation" ]
                            , span [ class "icon-bar" ]
                                []
                            , span [ class "icon-bar" ]
                                []
                            , span [ class "icon-bar" ]
                                []
                            ]
                        ]
                    , div [ class "collapse navbar-collapse", id "bs-example-navbar-collapse-1" ]
                        [ ul [ class "nav navbar-nav" ]
                            [ li [] [ aForPath Navigate "/" [] [ text "Home" ] ]
                            , li [] [ aForPath Navigate "/about" [] [ text "About" ] ]
                            , li [] [ aForPath Navigate "/tools" [] [ text "Tools" ] ]
                            , li [] [ aForPath Navigate "/examples" [] [ text "Examples" ] ]
                            , li [] [ aForPath Navigate "/organizations" [] [ text "Organizations" ] ]
                            , li [] [ aForPath Navigate "/help" [] [ text "Help" ] ]
                            ]
                        , Html.form
                            [ class "navbar-form navbar-right"
                            , onSubmit Search
                            ]
                            [ div [ class "form-group search-bar" ]
                                [ span [ attribute "aria-hidden" "true", class "glyphicon glyphicon-search" ]
                                    []
                                , input
                                    [ class "form-control"
                                    , onInput SearchInputChanged
                                    , placeholder "Search for a tool, example or organization"
                                    , type' "search"
                                    , value model.searchInputValue
                                    ]
                                    []
                                ]
                            ]
                        ]
                    ]
                ]
            ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
