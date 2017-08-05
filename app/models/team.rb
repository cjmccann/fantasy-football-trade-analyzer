class Team < ApplicationRecord
  serialize :player_arr
  belongs_to :league
  belongs_to :user

  def self.from_league_init(league)
    where(league_id: league.id, manager_id: league.manager_id).first_or_create do |team|
      team_data = league.user.api_client.get_team_metadata(league.game_id, league.league_id, league.manager_id)

      team.name = team_data['name']
      team.icon_url = team_data['team_logos']['team_logo']['url']
      team.manager_id = league.manager_id
      team.league_id = league.id
      team.imported = false
      team.user = league.user
      team.player_arr = []
    end
  end

  def import
    self.imported = true
    
    if self.user.favorite_team.nil?
      self.user.favorite_team = self.id
    end

    add_all_players

    self.user.save
    self.save
  end

  def add_all_players
    data = self.user.api_client.get_all_players_from_team(self.league.game_id, self.league.league_id, self.league.manager_id)

    data.each do |player|
      player = Player.from_team_init(player)
      self.player_arr.push(player.id)
    end
  end
end