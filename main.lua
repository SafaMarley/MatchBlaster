-- runs on start of the game
function love.load()
  love.window.setTitle("Match Blaster")
  -- set up the window size
  love.window.setMode(640, 800)

  -- set up the game grid and tile size
  boardWidth = 10
  boardHeight = 10
  tileSize = 64
  -- initialize the grid container
  board = {}

  -- set up the default moves and score
  movesLeft = 10
  highScore = 0

  -- define the type enum to determine tile type
  types = {
    None = 0,
    Blue = 1,
    Brown = 2,
    Gray = 3,
    Green = 4,
    Red = 5,
    Yellow = 6,
    Horizontal = 7,
    Vertical = 8,
    Bomb = 9,
  }

  -- create the tiles into grids
  for x = 1, boardWidth do
    board[x] = {}
    for y = 1, boardHeight do
      board[x][y] = {
        x = x,
        y = y,
        -- randomly assign a tile type into the grid
        type = love.math.random(1, 6)
      }
    end
  end
end

-- runs on each frame that game runs
function love.update(dt)
  for x = 1, boardWidth do
    for y = boardHeight - 1, 1, -1 do
      local tile = board[x][y]
      -- check if the tile is non empty tile
      if tile.type > 0 then
        local tileBelow = board[x][y + 1]
        -- check if the below tile is an empty tile
        if tileBelow.type == 0 then
          -- shift the tile down if the both states are valid
          board[x][y] = tileBelow
          board[x][y + 1] = tile
          tile.y = y + 1
          tileBelow.y = y
        end
      end
    end
  end

  for x = 1, boardWidth do
    -- check if there is an empty tile on top grid
    local tile = board[x][1]
    if tile.type == 0 then
      -- spawn a new tile on empty grid
      tile.type = love.math.random(1, 6)
    end
  end
end

-- render the game on screen
function love.draw()
  for x = 1, boardWidth do
    for y = 1, boardHeight do
      -- calculate the position of the tile
      local xPos = (x - 1) * tileSize
      local yPos = (y - 1) * tileSize

      -- draw the tile
      love.graphics.rectangle("line", xPos, yPos, tileSize, tileSize)
      
      -- check if tile is not empty
      local tile = board[x][y]
      if tile.type ~= 0 then
        -- load the proper tile image from project directory
        local tileImage = love.graphics.newImage("images/tile"..tile.type..".png")
        love.graphics.draw(tileImage, xPos, yPos)
      end
    end
  end
  -- render ui to show score and move count
  love.graphics.print('High Score: '..highScore, 100, 720)
  love.graphics.print('Moves left: '..movesLeft, 450, 720)
end

-- mouse click event
function love.mousepressed(x, y, button)
  -- check if left mouse button is clicked
  if button == 1 then
    -- check if any moves left
    if movesLeft <= 0 then
      return
    end

    -- calculate the clicked tile's position on the board
    local clickedTileX = math.floor(x / tileSize) + 1
    local clickedTileY = math.floor(y / tileSize) + 1
    -- check if the click is on the board or not
    if clickedTileX > boardWidth or clickedTileY > boardHeight then
      return
    end
    -- get the clicked tile
    local clickedTile = board[clickedTileX][clickedTileY]
    -- find tile matches recursively
    if clickedTile.type == 0 then
      return
    end

    matches = {}
    if clickedTile.type < 7 then
      matches = findMatches(clickedTileX, clickedTileY, clickedTile.type, {})

      blastTiles(matches)

      if #matches > 7 then
        clickedTile.type = 9
      elseif #matches > 5 then
        clickedTile.type = 8
      elseif #matches > 3 then
        clickedTile.type = 7
      end

    elseif clickedTile.type == 7 then
      for i = boardHeight, 1, -1 do
        table.insert(matches, board[i][clickedTileY])
      end
      blastTiles(matches)

    elseif clickedTile.type == 8 then
      for i = boardHeight, 1, -1 do
        table.insert(matches, board[clickedTileX][i])
      end
      blastTiles(matches)

    elseif clickedTile.type == 9 then
      table.insert(matches, clickedTile)
      if clickedTileX < boardWidth then
        table.insert(matches, board[clickedTileX + 1][clickedTileY])
        if clickedTileY < boardHeight then
          table.insert(matches, board[clickedTileX + 1][clickedTileY + 1])
        elseif clickedTileY > 1 then
          table.insert(matches, board[clickedTileX + 1][clickedTileY - 1])
        end
      end
      if clickedTileX > 1 then
        table.insert(matches, board[clickedTileX - 1][clickedTileY])
        if clickedTileY > 1 then
          table.insert(matches, board[clickedTileX - 1][clickedTileY - 1])
        elseif clickedTileY < boardHeight then
          table.insert(matches, board[clickedTileX - 1][clickedTileY + 1])
        end
      end
      if clickedTileY < boardHeight then
        table.insert(matches, board[clickedTileX][clickedTileY + 1])
      end
      if clickedTileY > 1 then
        table.insert(matches, board[clickedTileX][clickedTileY - 1])
      end
      blastTiles(matches)
    end

    -- score keeps track of the highest chunk of tile you have blasted
    if #matches > highScore then
      highScore = #matches
    end
    
    -- set the move count and check if player is lost or not
    movesLeft = movesLeft - 1
    if movesLeft == 0 then
      love.window.showMessageBox("Game Over", "No moves left!\nYour score is "..highScore, "error")
      --TODO: show game over screen here
    end
  end
end

-- finds the adjacent tiles that matches the type of tile you clicked on
function findMatches(clickedX, clickedY, tileType, tileList)
  -- return if the tile is already in blast
  if isContains(tileList, board[clickedX][clickedY]) then
    return
  end
  
  -- add the tile into the blast list
  table.insert(tileList, board[clickedX][clickedY])

  -- check if the adjacents exist and then check further recursively
  if clickedX < boardWidth then
    if board[clickedX + 1][clickedY].type == tileType then
      findMatches(clickedX + 1, clickedY, tileType, tileList)
    end
  end
  if clickedX > 1 then
    if board[clickedX - 1][clickedY].type == tileType then
      findMatches(clickedX - 1, clickedY, tileType, tileList)
    end
  end
  if clickedY < boardHeight then
    if board[clickedX][clickedY + 1].type == tileType then
      findMatches(clickedX, clickedY + 1, tileType, tileList)
    end
  end
  if clickedY > 1 then
    if board[clickedX][clickedY - 1].type == tileType then
      findMatches(clickedX, clickedY - 1, tileType, tileList)
    end
  end
    
  -- return matched tiles
  return tileList
end

function isContains(list, element)
  for key, member in pairs(list) do
    if element == member then
      return true
    end
  end
  return false
end

function blastTiles(blastZone)
  -- empty the tiles affected from the blast
  for key, tile in pairs(blastZone) do
    tile.type = 0
  end
end