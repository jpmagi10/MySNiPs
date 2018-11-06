class UsersController < ApiController
  def new
    @user = User.new
  end

  def create
    Role.create(role_name: "usuario_final")
    role = Role.find_by(role_name: "usuario_final")
    @user = User.new(user_params)
    @user.role_id = role.id
    if @user.save
      # If user saves in the db successfully:
      flash[:notice] = "Account created successfully!"
      redirect_to root_path
    else
      # If user fails model validation - probably a bad password or duplicate email:
      flash.now.alert = "Oops, couldn't create account. Please make sure you are using a valid data and try again."
      render :new
    end
  end

  # GET /users/
  def index
    # Common or unlloged users can't see other users
    return json_response(error: "Invalid credentials") unless authority_valid?

    # Admins can see all users
    return json_response(User.all) if @role.role_name == "admin"

    # While labs can only see their users
    common_role_id = Role.find_by(role_name: "usuario_final").id
    @users = User .where("identifier LIKE (?) AND role_id = (?)", "#{@current_api_user.identifier}%", common_role_id.to_s)
                  .select("id, identifier, password, created_at, last_login")

    json_response(@users)
  end

  # GET /users/:id
  def show
    # Common or unlloged users can't see other users
    return json_response(error: "Invalid credentials") unless authority_valid?

    # Labs can only see their own users
    params[:identifier] = @current_api_user.identifier + params[:identifier] unless @role.role_name == "admin"
    @user = User.select("id, identifier, password, created_at, last_login")
                .find_by(identifier: params[:identifier])
    json_response(@user)
  end

  private

  def user_params
    # strong parameters - whitelist of allowed fields #=> permit(:name, :email, ...)
    # that can be submitted by a form to the user model #=> require(:user)
    params.require(:user).permit(:identifier, :password)
  end
end
